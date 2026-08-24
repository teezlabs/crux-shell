import QtQuick
import qs.Modules.Bar.Extras

// Plain app-launcher icon on the bar; the search UI lives in the separate
// LauncherWindow popup.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  implicitWidth: 32
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  LauncherWindow {
    id: menu
    targetScreen: root.screen
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: 4
    radius: 2
    color: mouseArea.containsMouse ? "#45475a" : "transparent"

    // Geometric grid-of-dots glyph — no font/emoji glyph dependency.
    Grid {
      anchors.centerIn: parent
      columns: 3
      spacing: 2
      Repeater {
        model: 9
        delegate: Rectangle {
          width: 3
          height: 3
          radius: 1
          color: "#cdd6f4"
        }
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
