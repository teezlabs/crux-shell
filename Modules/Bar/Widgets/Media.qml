import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Commons
import qs.Modules.Bar.Extras

// v2 spec §6.1 Media module: 4-bar equaliser (2px wide, heights 5/11/7/9,
// primary) + truncated "Title — Artist", max width 210. Click opens the
// media popover (MediaPlayerWindow.qml, §6.6).
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  // Portrait-horizontal bar flag (see BarWidgetLoader.qml); title shrinks here to avoid overlapping Clock.
  property bool contentVertical: vertical
  property bool invertChamfer: false

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
  readonly property string trackTitle: activePlayer && activePlayer.trackTitle ? String(activePlayer.trackTitle).replace(/[\r\n]/g, "") : ""
  readonly property string trackArtist: activePlayer && activePlayer.trackArtist ? activePlayer.trackArtist : ""
  readonly property string displayText: trackArtist !== "" ? trackArtist + " — " + trackTitle : trackTitle

  visible: !!activePlayer && trackTitle !== ""

  implicitWidth: !visible ? 0 : module.implicitWidth
  implicitHeight: !visible ? 0 : module.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarModule {
    id: module
    vertical: root.vertical
    invertChamfer: root.invertChamfer

    // Vertical bar: just the equaliser, no title/artist text — nothing
    // resembling "Title — Artist" fits a ~30px-wide column, and eliding it
    // down to nothing would just be noise. Horizontal: bars + truncated text.
    Row {
      visible: !root.vertical
      spacing: 8

      Row {
        id: eqRowH
        spacing: 2
        readonly property var barHeights: [5, 11, 7, 9]
        readonly property int maxBarHeight: 11

        Repeater {
          model: 4
          delegate: Rectangle {
            required property int index
            width: 2
            height: eqRowH.barHeights[index]
            y: eqRowH.maxBarHeight - height
            color: Color.primary
            opacity: root.isPlaying ? 1 : 0.35
          }
        }
      }

      Text {
        text: root.displayText
        color: Color.surfaceText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySize
        font.letterSpacing: Tokens.bodySize * Tokens.bodyTracking
        elide: Text.ElideRight
        width: Math.min(implicitWidth, root.contentVertical && !root.vertical ? 70 : 210)
      }
    }

    Row {
      visible: root.vertical
      spacing: 2
      readonly property var barHeights: [5, 11, 7, 9]
      readonly property int maxBarHeight: 11

      Repeater {
        model: 4
        delegate: Rectangle {
          required property int index
          width: 2
          height: parent.barHeights[index]
          y: parent.maxBarHeight - height
          color: Color.primary
          opacity: root.isPlaying ? 1 : 0.35
        }
      }
    }
  }

  MediaPlayerWindow {
    id: popover
    targetScreen: root.screen
  }

  HoverHandler {
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    onTapped: popover.toggle()
  }
}
