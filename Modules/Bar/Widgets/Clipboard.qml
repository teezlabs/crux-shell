import QtQuick
import qs.Modules.Bar.Extras

// Plain clipboard icon on the bar; the history list lives in the separate
// ClipboardMenuWindow popup.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  implicitWidth: 32
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  ClipboardMenuWindow {
    id: menu
    targetScreen: root.screen
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: 4
    radius: 2
    color: mouseArea.containsMouse ? "#45475a" : "transparent"

    // Geometric clipboard glyph — a small rectangle with a clip notch,
    // no font/emoji glyph dependency (see crux skill: font gotchas).
    Item {
      anchors.centerIn: parent
      width: 12
      height: 14

      Rectangle {
        anchors.fill: parent
        radius: 1
        color: "transparent"
        border.color: "#cdd6f4"
        border.width: 1
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: -2
        width: 6
        height: 4
        radius: 1
        color: "#1e1e2e"
        border.color: "#cdd6f4"
        border.width: 1
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: menu.toggle()
  }
}
