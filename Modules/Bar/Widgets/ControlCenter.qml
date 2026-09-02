import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras

// Opens the Control Center popup via IPC — StatusGroup owns the one ControlCenterWindow instance per screen.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false // true bar orientation (left/right bar)

  implicitWidth: module.implicitWidth
  implicitHeight: module.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarModule {
    id: module
    // Standard-sized like every other module — no longer growing to match
    // Sound's portrait-compact stacked height (was making the whole
    // horizontal bar look thicker than intended on a portrait screen).
    vertical: root.vertical
    topPadding: 8
    bottomPadding: 8
    // Standard (non-inverted) chamfer, so this module's own bottom-left
    // cut lines up with the floating outer bar strip's bottom-left cut
    // instead of contradicting it.
    invertChamfer: false

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
