import QtQuick
import qs.Commons

// v2-styled toggle switch: chamfered track (radius: 0 per hard rule 1,
// same two-opposite-corner convention as every other chamfered element),
// primaryContainer fill + primary border when on, sliding square thumb.
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
    fillColor: root.checked ? Color.primaryContainer : Color.surfaceContainerHigh
    strokeColor: root.checked ? Color.primary : Color.outline
    strokeWidth: Tokens.borderModule
  }

  Rectangle {
    id: thumb
    width: parent.height - 6
    height: parent.height - 6
    anchors.verticalCenter: parent.verticalCenter
    x: root.checked ? parent.width - width - 3 : 3
    color: root.checked ? Color.primary : Color.labelText

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
