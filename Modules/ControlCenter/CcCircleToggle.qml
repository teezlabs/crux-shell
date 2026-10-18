import QtQuick
import qs.Commons

// Round icon toggle for Control Center's top row, a deliberate exception to the no-radius rule.
// Inactive fill is a step above the card, or the toggle reads as a bare floating icon.
Item {
  id: root

  property bool active: false
  property bool available: true
  default property alias content: contentItem.data
  signal tapped

  implicitWidth: 40
  implicitHeight: 40

  Rectangle {
    anchors.fill: parent
    radius: width / 2
    color: root.active ? Colors.primary : (hover.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainerLow)
    border.color: root.active ? "transparent" : Colors.outlineVariant
    border.width: root.active ? 0 : Tokens.borderModule
    opacity: root.available ? 1 : 0.4
  }

  Item {
    id: contentItem
    anchors.fill: parent
  }

  HoverHandler {
    id: hover
    enabled: root.available
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    enabled: root.available
    onTapped: root.tapped()
  }
}
