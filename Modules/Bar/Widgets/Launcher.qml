import QtQuick
import qs.Modules.Launcher
import qs.Commons
import qs.Modules.Bar.Extras

// App-launcher icon; the search UI is LauncherWindow.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool invertChamfer: false

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
    invertChamfer: root.invertChamfer
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
          color: Colors.surfaceText
        }
      }
    }
  }
}
