import QtQuick
import qs.Modules.Bar.Extras
import qs.Commons

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
          color: Color.mOnSurface
        }
      }
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
