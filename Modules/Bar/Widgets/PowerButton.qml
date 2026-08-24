import QtQuick
import qs.Modules.Bar.Extras
import qs.Commons

// Plain power icon on the bar. The honeycomb action menu lives in the
// separate PowerMenuWindow popup — the bar strip is too thin to host it.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  implicitWidth: 32
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  PowerMenuWindow {
    id: menu
    targetScreen: root.screen
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: 4
    radius: 6
    color: hoverHandler.hovered ? Color.mOutline : "transparent"

    Text {
      anchors.centerIn: parent
      text: "⏻"
      font.pixelSize: 16
      color: Color.mOnSurface
    }
  }

  HoverHandler {
    id: hoverHandler
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: menu.toggle()
  }
}
