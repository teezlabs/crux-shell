import QtQuick
import qs.Modules.Bar.Extras
import qs.Commons

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
        border.color: Color.mOnSurface
        border.width: 1
      }

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: -2
        width: 6
        height: 4
        radius: 1
        color: Color.mSurface
        border.color: Color.mOnSurface
        border.width: 1
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
