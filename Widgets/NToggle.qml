import QtQuick
import qs.Commons

// Toggle switch: chamfered fill-only track, primary when on, sliding
// square thumb.
Item {
  id: root

  property bool checked: false
  signal toggled(bool checked)

  implicitWidth: 36
  implicitHeight: 20

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferIcon
    cutTopRight: true
    cutBottomLeft: true
    fillColor: root.checked ? Colors.primary : Colors.surfaceContainerHigh
  }

  Rectangle {
    id: thumb
    width: parent.height - 6
    height: parent.height - 6
    anchors.verticalCenter: parent.verticalCenter
    x: root.checked ? parent.width - width - 3 : 3
    color: root.checked ? Colors.primaryText : Colors.labelText

    Behavior on x {
      NumberAnimation {
        duration: Tokens.durationPanel
        easing.type: Tokens.easingPanel
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
