import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Commons

// Compact "now playing" readout on the bar; hidden entirely when nothing is
// playing. API pattern (Mpris.players.values, MprisPlaybackState, player
// control methods) ported from noctalia's Services/Media/MediaService.qml.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var activePlayer: {
    for (var i = 0; i < players.length; i++) {
      if (players[i] && players[i].playbackState === MprisPlaybackState.Playing)
        return players[i];
    }
    return players.length > 0 ? players[0] : null;
  }
  readonly property bool isPlaying: activePlayer ? activePlayer.playbackState === MprisPlaybackState.Playing : false
  readonly property string trackTitle: activePlayer && activePlayer.trackTitle ? String(activePlayer.trackTitle).replace(/[\r\n]/g, "") : ""
  readonly property string trackArtist: activePlayer && activePlayer.trackArtist ? activePlayer.trackArtist : ""

  visible: !!activePlayer && trackTitle !== ""

  readonly property string displayText: trackArtist !== "" ? trackArtist + " – " + trackTitle : trackTitle

  // Horizontal: one elided line next to the icon, sized to content.
  // Vertical: a narrow fixed-width column with the icon on top and the
  // title wrapped underneath — one wide line like the horizontal layout
  // simply doesn't fit a ~32px-wide bar, same reasoning as Clock.qml.
  implicitWidth: !visible ? 0 : (root.vertical ? 32 : (row.implicitWidth + 16))
  implicitHeight: !visible ? 0 : (root.vertical ? (column.implicitHeight + 10) : 32)
  width: implicitWidth
  height: implicitHeight

  // Two thin vertical bars = "playing" glyph; a right-pointing triangle
  // shape for "paused" — geometric, no font glyph dependency. Shared
  // between both layouts below via a Component so the drawing logic
  // isn't duplicated.
  Component {
    id: playPauseGlyph

    Item {
      width: 10
      height: 12

      Row {
        visible: root.isPlaying
        anchors.centerIn: parent
        spacing: 2
        Rectangle {
          width: 3
          height: 12
          color: Color.mPrimary
        }
        Rectangle {
          width: 3
          height: 12
          color: Color.mPrimary
        }
      }

      Canvas {
        visible: !root.isPlaying
        anchors.fill: parent
        onPaint: {
          var ctx = getContext("2d");
          ctx.reset();
          ctx.fillStyle = Color.mOnSurfaceVariant;
          ctx.beginPath();
          ctx.moveTo(0, 0);
          ctx.lineTo(10, 6);
          ctx.lineTo(0, 12);
          ctx.closePath();
          ctx.fill();
        }
      }
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusXXS
    color: hoverHandler.hovered ? Color.alpha(Color.mPrimary, 0.16) : "transparent"
    border.color: Color.alpha(Color.mPrimary, 0.55)
    border.width: hoverHandler.hovered ? 1 : 0
    scale: hoverHandler.hovered ? 1.1 : 1.0
    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }
    Behavior on scale {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutBack
      }
    }

    Row {
      id: row
      visible: !root.vertical
      anchors.centerIn: parent
      spacing: 6

      Loader {
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: playPauseGlyph
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.displayText
        color: Color.mOnSurface
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: 12
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 220)
      }
    }

    Column {
      id: column
      visible: root.vertical
      anchors.centerIn: parent
      spacing: 4
      width: 28

      Loader {
        anchors.horizontalCenter: parent.horizontalCenter
        sourceComponent: playPauseGlyph
      }

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.displayText
        color: Color.mOnSurface
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: 10
        wrapMode: Text.WordWrap
        maximumLineCount: 3
        elide: Text.ElideRight
      }
    }
  }

  HoverHandler {
    id: hoverHandler
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onTapped: function (point, button) {
      if (!root.activePlayer)
        return;
      if (button === Qt.RightButton) {
        root.activePlayer.next();
      } else {
        if (root.isPlaying)
          root.activePlayer.pause();
        else
          root.activePlayer.play();
      }
    }
  }
}
