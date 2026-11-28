import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.Commons
import qs.Modules.ControlCenter
import qs.Modules.Popups
import qs.Services
import qs.Widgets

// Now-playing page for the Control Center: art, a visualizer, seek, transport, and every player to switch between.
ColumnLayout {
  id: root

  // Shown as a Control Center sub-page: the header gets a back arrow.
  property bool showBack: false
  signal backRequested
  // True while on screen; the visualizer holds cava only then.
  property bool panelActive: false

  spacing: Tokens.spaceLg

  readonly property var player: MediaService.activePlayer
  readonly property bool hasPlayer: !!root.player

  PopupHeader {
    title: "NOW PLAYING"
    meta: root.hasPlayer ? root.player.identity : ""
    showBack: root.showBack
    onBackTapped: root.backRequested()
  }

  NetSection {
    visible: !root.hasPlayer

    NText {
      Layout.fillWidth: true
      Layout.margins: Tokens.spaceSm
      text: "Nothing playing"
      size: NText.Size.BodySm
      color: Colors.labelText
    }
  }

  NetSection {
    visible: root.hasPlayer
    active: MediaService.isPlaying

    RowLayout {
      Layout.fillWidth: true
      Layout.margins: Tokens.spaceXs
      spacing: Tokens.spaceLg

      Item {
        Layout.preferredWidth: 96
        Layout.preferredHeight: 96

        Rectangle {
          anchors.fill: parent
          color: Colors.surfaceContainerHigh
        }
        Image {
          id: art
          anchors.fill: parent
          source: root.hasPlayer ? (root.player.trackArtUrl || "") : ""
          sourceSize.width: 192
          sourceSize.height: 192
          fillMode: Image.PreserveAspectCrop
          asynchronous: true
        }
        NSymbol {
          anchors.centerIn: parent
          visible: art.status !== Image.Ready
          name: "music_note"
          size: 36
          color: Colors.labelText
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Tokens.spaceXs

        NText {
          Layout.fillWidth: true
          text: root.hasPlayer ? (root.player.trackTitle || root.player.identity) : ""
          size: NText.Size.BodyLg
          font.weight: Font.DemiBold
          elide: Text.ElideRight
          maximumLineCount: 2
          wrapMode: Text.WordWrap
        }
        NText {
          Layout.fillWidth: true
          visible: text !== ""
          text: root.hasPlayer ? (root.player.trackArtist || "") : ""
          size: NText.Size.BodySm
          color: Colors.surfaceTextMuted
          elide: Text.ElideRight
        }
        NText {
          Layout.fillWidth: true
          visible: text !== ""
          text: root.hasPlayer ? (root.player.trackAlbum || "").toUpperCase() : ""
          tracking: true
          size: NText.Size.LabelXs
          color: Colors.labelText
          elide: Text.ElideRight
        }
      }
    }

    CcSpectrum {
      Layout.fillWidth: true
      Layout.topMargin: Tokens.spaceSm
      implicitHeight: 48
      running: root.panelActive && root.hasPlayer
    }

    CcLevelSlider {
      Layout.fillWidth: true
      Layout.topMargin: Tokens.spaceSm
      value: MediaService.length > 0 ? (MediaService.position / MediaService.length) * 100 : 0
      interactive: root.hasPlayer && root.player.canSeek
      onMoved: pct => {
        if (root.hasPlayer && root.player.canSeek)
          root.player.position = (pct / 100) * MediaService.length;
      }
    }

    RowLayout {
      Layout.fillWidth: true

      NText {
        text: MediaService.fmtTime(MediaService.position)
        size: NText.Size.Caption
        color: Colors.labelText
        font.features: {
          "tnum": 1
        }
      }
      Item {
        Layout.fillWidth: true
      }
      // Some players (browsers) report no length.
      NText {
        visible: MediaService.length > 0
        text: "-" + MediaService.fmtTime(Math.max(0, MediaService.length - MediaService.position))
        size: NText.Size.Caption
        color: Colors.labelText
        font.features: {
          "tnum": 1
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      Layout.topMargin: Tokens.spaceXs
      spacing: Tokens.spaceSm

      CcIconButton {
        Layout.fillWidth: true
        symbol: "shuffle"
        tooltip: "Shuffle"
        tone: root.hasPlayer && root.player.shuffle ? "active" : ""
        available: root.hasPlayer && root.player.shuffleSupported
        onTapped: root.player.shuffle = !root.player.shuffle
      }
      CcIconButton {
        Layout.fillWidth: true
        symbol: "skip_previous"
        tooltip: "Previous"
        available: root.hasPlayer && root.player.canGoPrevious
        onTapped: root.player.previous()
      }
      CcIconButton {
        Layout.fillWidth: true
        symbol: MediaService.isPlaying ? "pause" : "play_arrow"
        tooltip: MediaService.isPlaying ? "Pause" : "Play"
        tone: "active"
        available: root.hasPlayer && (root.player.canPlay || root.player.canPause)
        onTapped: root.player.togglePlaying()
      }
      CcIconButton {
        Layout.fillWidth: true
        symbol: "skip_next"
        tooltip: "Next"
        available: root.hasPlayer && root.player.canGoNext
        onTapped: root.player.next()
      }
      CcIconButton {
        Layout.fillWidth: true
        readonly property int loop: root.hasPlayer ? root.player.loopState : MprisLoopState.None
        symbol: loop === MprisLoopState.Track ? "repeat_one" : "repeat"
        tooltip: loop === MprisLoopState.None ? "Repeat" : loop === MprisLoopState.Playlist ? "Repeat all" : "Repeat one"
        tone: loop !== MprisLoopState.None ? "active" : ""
        available: root.hasPlayer && root.player.loopSupported
        onTapped: root.player.loopState = loop === MprisLoopState.None ? MprisLoopState.Playlist : loop === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
      }
    }
  }

  // ---- Players: only when there's more than one to choose from ----
  NetSection {
    visible: MediaService.players.length > 1
    label: "PLAYERS"

    Repeater {
      model: MediaService.players

      delegate: NetRow {
        required property var modelData
        readonly property bool current: root.player === modelData
        symbol: "music_note"
        highlighted: current
        title: modelData.identity
        subtitle: modelData.trackTitle || (modelData.playbackState === MprisPlaybackState.Playing ? "Playing" : "Paused")
        onTapped: Settings.data.audio.preferredMediaPlayer = modelData.identity
      }
    }
  }
}
