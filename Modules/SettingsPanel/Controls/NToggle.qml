import QtQuick
import qs.Commons

// Styled pill switch — noctalia's own NToggle (Widgets/NToggle.qml there):
// a rounded track that fills solid mPrimary when on, with a circular thumb
// that slides and swaps fill/border color, replacing crux's old plain
// checkbox-square pattern used everywhere in the settings panel.
Item {
  id: root

  property bool checked: false
  signal toggled(bool checked)

  implicitWidth: 36
  implicitHeight: 20

  Rectangle {
    id: track
    anchors.fill: parent
    radius: height / 2
    color: root.checked ? Color.mPrimary : Color.mSurfaceVariant
    border.color: root.checked ? Color.mPrimary : Color.mOutline
    border.width: 1

    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }
    Behavior on border.color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }

    Rectangle {
      id: thumb
      width: parent.height - 6
      height: parent.height - 6
      radius: width / 2
      anchors.verticalCenter: parent.verticalCenter
      x: root.checked ? parent.width - width - 3 : 3
      color: root.checked ? Color.mOnPrimary : Color.mOnSurfaceVariant

      Behavior on x {
        NumberAnimation {
          duration: Style.animationFast
          easing.type: Easing.OutCubic
        }
      }
      Behavior on color {
        ColorAnimation {
          duration: Style.animationFast
        }
      }
    }
  }

  HoverHandler {
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    onTapped: root.toggled(!root.checked)
  }
}
