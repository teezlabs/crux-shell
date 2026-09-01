import QtQuick
import qs.Modules.Bar.Extras
import qs.Commons

// App-launcher icon on the bar; the search UI lives in the separate
// LauncherWindow popup.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  LauncherWindow {
    id: menu
    targetScreen: root.screen
  }

  BarIconButton {
    id: btn
    onTapped: menu.toggle()

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
          color: Color.surfaceText
        }
      }
    }
  }
}
