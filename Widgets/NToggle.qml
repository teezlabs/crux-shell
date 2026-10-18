import QtQuick
import qs.Commons

// Chamfered toggle: primaryContainer fill and primary border when on, sliding square thumb.
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
    fillColor: root.checked ? Colors.primaryContainer : Colors.surfaceContainerHigh
    strokeColor: root.checked ? Colors.primary : Colors.outline
    strokeWidth: Tokens.borderModule
  }

  Rectangle {
    id: thumb
    width: parent.height - 6
    height: parent.height - 6
    anchors.verticalCenter: parent.verticalCenter
    x: root.checked ? parent.width - width - 3 : 3
    color: root.checked ? Colors.primary : Colors.labelText

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
