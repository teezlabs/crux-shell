import QtQuick
import qs.Modules.Bar.Extras
import qs.Commons

// Clipboard icon on the bar; the history list lives in the separate
// ClipboardMenuWindow popup.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  ClipboardMenuWindow {
    id: menu
    targetScreen: root.screen
  }

  BarIconButton {
    id: btn
    onTapped: {
      menu.triggerPos = root.mapToItem(null, 0, 0);
      menu.toggle();
    }

    // Geometric clipboard glyph — a small rectangle with a clip notch.
    Item {
      anchors.centerIn: parent
      width: 12
      height: 14

      Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: Color.surfaceText
        border.width: 1
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: -2
        width: 6
        height: 4
        color: Color.surface
        border.color: Color.surfaceText
        border.width: 1
      }
    }
  }
}
