import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras

// Bar icon opening the Control Center popup directly (StatusGroup's NET/VOL
// segments also open it). StatusGroup already owns the one ControlCenterWindow
// instance/IPC registration for this screen (two instances would collide —
// see the crux skill's IPC section) — this widget just calls it via IPC
// rather than instantiating a second window.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false // true bar orientation (left/right bar)
  property bool contentVertical: vertical // Sound's effective-stacked flag; see crux skill's notes.md

  implicitWidth: module.implicitWidth
  implicitHeight: module.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarModule {
    id: module
    // Matches Sound's height exactly via the measuring Column below — see
    // crux skill's notes.md for why.
    vertical: root.contentVertical
    topPadding: 8
    bottomPadding: 8
    invertChamfer: !root.vertical

    Item {
      id: slot
      width: 24
      height: module.vertical ? measureCol.implicitHeight : 16

      // Invisible spacer matching Sound.qml's stacked-text metrics.
      Column {
        id: measureCol
        visible: module.vertical
        width: 24
        Text {
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: "00"
          opacity: 0
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
        Text {
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: "VOL"
          opacity: 0
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize - 1
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
      }

      ArchLogo {
        anchors.centerIn: parent
        width: 16
        height: 16
      }
    }
  }

  HoverHandler {
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: {
      var pos = root.mapToItem(null, 0, 0);
      Quickshell.execDetached(["qs", "ipc", "-c", "crux", "call", "controlCenter_" + (root.screen ? root.screen.name : "0"), "openAt", String(pos.x), String(pos.y)]);
    }
  }
}
