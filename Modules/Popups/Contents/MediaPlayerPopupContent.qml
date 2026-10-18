import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Popups

// Media player popup content: every control is live MPRIS, gated on the
// player's own can*/Supported flags. No fabricated "year".
ColumnLayout {
  id: root

  spacing: Tokens.spaceLg

  readonly property var activePlayer: MediaService.activePlayer
  readonly property bool isPlaying: MediaService.isPlaying
  readonly property real position: MediaService.position
  readonly property real length: MediaService.length

  function fmtTime(seconds) {
    return MediaService.fmtTime(seconds);
  }

  PopupHeader {
    title: "MEDIA"
    meta: root.activePlayer ? root.activePlayer.identity : ""
  }

  NText {
    visible: !root.activePlayer
    text: "Nothing playing"
    color: Colors.labelText
    size: NText.Size.BodySm
  }

  RowLayout {
    Layout.fillWidth: true
    visible: !!root.activePlayer
    spacing: 14

    Item {
      Layout.preferredWidth: 92
      Layout.preferredHeight: 92

      Chamfer {
        anchors.fill: parent
        chamferSize: Tokens.chamferModule
        cutTopRight: true
        cutBottomLeft: true
        fillColor: Colors.surfaceContainer
        strokeColor: Colors.outline
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
          ctx.strokeStyle = Colors.surfaceContainerHigh;
          ctx.lineWidth = 2;
          for (var x = -height; x < width; x += 10) {
            ctx.beginPath();
            ctx.moveTo(x, 0);
            ctx.lineTo(x + height, height);
            ctx.stroke();
          }
        }
      }

      NText {
        tracking: true
        anchors.centerIn: parent
        visible: !root.activePlayer || root.activePlayer.trackArtUrl === ""
        text: "ALBUM\nART"
        horizontalAlignment: Text.AlignHCenter
        color: Colors.labelText
        size: NText.Size.LabelXs
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 3

      NText {
        Layout.fillWidth: true
        text: root.activePlayer ? root.activePlayer.trackTitle : ""
        color: Colors.surfaceText
        size: NText.Size.BodyLg
        font.weight: Font.DemiBold
        elide: Text.ElideRight
      }
      NText {
        text: root.activePlayer ? root.activePlayer.trackArtist : ""
        color: Colors.surfaceText
      }
      NText {
        tracking: true
        visible: root.activePlayer && root.activePlayer.trackAlbum !== ""
        text: root.activePlayer ? root.activePlayer.trackAlbum : ""
        color: Colors.labelText
        size: NText.Size.Caption
      }
    }
  }

  SegMeter {
    Layout.fillWidth: true
    visible: !!root.activePlayer
    cellCount: Tokens.meterMediaSeekCells
    cellHeight: Tokens.meterMediaSeekCellHeight
    value: root.length > 0 ? (root.position / root.length) * 100 : 0
    interactive: !!root.activePlayer && root.activePlayer.canSeek
    filledColor: Colors.primary
    emptyColor: Colors.surfaceContainerHigh
    onMoved: pct => {
      if (root.activePlayer && root.activePlayer.canSeek)
        root.activePlayer.position = (pct / 100) * root.length;
    }
  }

  RowLayout {
    Layout.fillWidth: true
    visible: !!root.activePlayer

    NText {
      text: root.fmtTime(root.position)
      color: Colors.labelText
      size: NText.Size.Caption
    }
    Item {
      Layout.fillWidth: true
    }
    NText {
      text: "-" + root.fmtTime(root.length - root.position)
      color: Colors.labelText
      size: NText.Size.Caption
    }
  }

  RowLayout {
    Layout.fillWidth: true
    visible: !!root.activePlayer
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
