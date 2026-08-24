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

  implicitWidth: visible ? row.implicitWidth + 16 : 0
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  Rectangle {
    anchors.fill: parent
    radius: 2
    color: mouseArea.containsMouse ? "#45475a" : "transparent"

    Row {
      id: row
      anchors.centerIn: parent
      spacing: 6

      // Two thin vertical bars = "playing" glyph; a right-pointing triangle
      // shape for "paused" — geometric, no font glyph dependency.
      Item {
        width: 10
        height: 12
        anchors.verticalCenter: parent.verticalCenter

        Row {
          visible: root.isPlaying
          anchors.centerIn: parent
          spacing: 2
          Rectangle {
            width: 3
            height: 12
            color: "#89b4fa"
          }
          Rectangle {
            width: 3
            height: 12
            color: "#89b4fa"
          }
        }

        Canvas {
          visible: !root.isPlaying
          anchors.fill: parent
          onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = "#6c7086";
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(10, 6);
            ctx.lineTo(0, 12);
            ctx.closePath();
            ctx.fill();
          }
        }
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.trackArtist !== "" ? root.trackArtist + " – " + root.trackTitle : root.trackTitle
        color: "#cdd6f4"
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: 12
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 220)
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function (mouse) {
      if (!root.activePlayer)
        return;
      if (mouse.button === Qt.RightButton) {
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
