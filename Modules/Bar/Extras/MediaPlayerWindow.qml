import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import qs.Commons
import qs.Modules.Bar.Extras

// Media player popover, all controls live MPRIS, gated on the player's own can*/Supported flags. No fabricated "year".
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var activePlayer: {
    var preferred = Settings.isLoaded ? Settings.data.audio.preferredMediaPlayer : "";
    if (preferred !== "") {
      for (var j = 0; j < players.length; j++)
        if (players[j] && players[j].identity === preferred)
          return players[j];
    }
    for (var i = 0; i < players.length; i++) {
      if (players[i] && players[i].playbackState === MprisPlaybackState.Playing)
        return players[i];
    }
    return players.length > 0 ? players[0] : null;
  }
  readonly property bool isPlaying: activePlayer ? activePlayer.playbackState === MprisPlaybackState.Playing : false

  // MPRIS doesn't reliably emit positionChanged during playback; _positionTick forces re-evaluation every second.
  property int _positionTick: 0
  readonly property real position: {
    _positionTick;
    return activePlayer ? activePlayer.position : 0;
  }
  readonly property real length: activePlayer ? activePlayer.length : 0

  Timer {
    interval: 1000
    running: root.visible && root.isPlaying
    repeat: true
    onTriggered: root._positionTick++
  }

  function fmtTime(seconds) {
    if (!seconds || seconds < 0)
      return "0:00";
    var m = Math.floor(seconds / 60);
    var s = Math.floor(seconds % 60);
    return m + ":" + String(s).padStart(2, "0");
  }

  function toggle() {
    visible = !visible;
  }


  visible: false
  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-media-player"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "mediaPlayer"
    function toggle() {
      root.toggle();
    }
    function open() {
      root.visible = true;
    }
    function close() {
      root.visible = false;
    }
  }

  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.visible = false
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.visible = false
  }

  Item {
    id: card
    width: 396
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: Settings.data.bar.thickness + Settings.data.bar.floatMargin * 2 + 8
    height: column.implicitHeight + 28
    visible: !!root.activePlayer

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutTopLeft: false
      cutTopRight: true
      cutBottomLeft: true
      cutBottomRight: false
      fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
      strokeColor: Color.outline
      strokeWidth: Tokens.borderPanel
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      id: column
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 14
      spacing: 12

      RowLayout {
        Layout.fillWidth: true
        spacing: 14

        Item {
          Layout.preferredWidth: 92
          Layout.preferredHeight: 92

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferModule
            cutTopRight: true
            cutBottomLeft: true
            fillColor: Color.surfaceContainer
            strokeColor: Color.outline
            strokeWidth: Tokens.borderModule
          }

          Image {
            anchors.fill: parent
            anchors.margins: Tokens.borderModule
            visible: root.activePlayer && root.activePlayer.trackArtUrl !== ""
            source: root.activePlayer ? root.activePlayer.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
          }

          // Diagonal-stripe placeholder when there's no art — same idea
          // the spec text calls for ("fall back to the diagonal-stripe
          // placeholder").
          Canvas {
            anchors.fill: parent
            anchors.margins: Tokens.borderModule
            visible: !root.activePlayer || root.activePlayer.trackArtUrl === ""
            onPaint: {
              var ctx = getContext("2d");
              ctx.reset();
              ctx.strokeStyle = Color.surfaceContainerHigh;
              ctx.lineWidth = 2;
              for (var x = -height; x < width; x += 10) {
                ctx.beginPath();
                ctx.moveTo(x, 0);
                ctx.lineTo(x + height, height);
                ctx.stroke();
              }
            }
          }

          Text {
            anchors.centerIn: parent
            visible: !root.activePlayer || root.activePlayer.trackArtUrl === ""
            text: "ALBUM\nART"
            horizontalAlignment: Text.AlignHCenter
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 3

          Text {
            text: root.activePlayer ? root.activePlayer.identity.toUpperCase() : ""
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }
          Text {
            Layout.fillWidth: true
            text: root.activePlayer ? root.activePlayer.trackTitle : ""
            color: Color.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodyLgSize
            font.weight: Font.DemiBold
            elide: Text.ElideRight
          }
          Text {
            text: root.activePlayer ? root.activePlayer.trackArtist : ""
            color: Color.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodySize
          }
          Text {
            visible: root.activePlayer && root.activePlayer.trackAlbum !== ""
            text: root.activePlayer ? root.activePlayer.trackAlbum : ""
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.captionSize
            font.letterSpacing: Tokens.captionSize * Tokens.captionTracking
          }
        }
      }

      SegMeter {
        Layout.fillWidth: true
        cellCount: Tokens.meterMediaSeekCells
        cellHeight: Tokens.meterMediaSeekCellHeight
        value: root.length > 0 ? (root.position / root.length) * 100 : 0
        interactive: !!root.activePlayer && root.activePlayer.canSeek
        filledColor: Color.primary
        emptyColor: Color.surfaceContainerHigh
        onMoved: pct => {
          if (root.activePlayer && root.activePlayer.canSeek)
            root.activePlayer.position = (pct / 100) * root.length;
        }
      }

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: root.fmtTime(root.position)
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.captionSize
        }
        Item {
          Layout.fillWidth: true
        }
        Text {
          text: "-" + root.fmtTime(root.length - root.position)
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.captionSize
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 1

        MpTransportButton {
          Layout.fillWidth: true
          glyph: "⤨"
          active: root.activePlayer && root.activePlayer.shuffle
          available: !!root.activePlayer && root.activePlayer.shuffleSupported
          onTapped: root.activePlayer.shuffle = !root.activePlayer.shuffle
        }
        MpTransportButton {
          Layout.fillWidth: true
          glyph: "⏮"
          available: !!root.activePlayer && root.activePlayer.canGoPrevious
          onTapped: root.activePlayer.previous()
        }
        MpTransportButton {
          Layout.fillWidth: true
          glyph: root.isPlaying ? "⏸" : "▶"
          active: root.isPlaying
          available: !!root.activePlayer && (root.activePlayer.canPlay || root.activePlayer.canPause)
          onTapped: root.activePlayer.togglePlaying()
        }
        MpTransportButton {
          Layout.fillWidth: true
          glyph: "⏭"
          available: !!root.activePlayer && root.activePlayer.canGoNext
          onTapped: root.activePlayer.next()
        }
        MpTransportButton {
          Layout.fillWidth: true
          glyph: "↻"
          active: root.activePlayer && root.activePlayer.loopState !== MprisLoopState.None
          available: !!root.activePlayer && root.activePlayer.loopSupported
          onTapped: {
            var next = root.activePlayer.loopState === MprisLoopState.None ? MprisLoopState.Playlist : (root.activePlayer.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None);
            root.activePlayer.loopState = next;
          }
        }
      }
    }
  }
}
