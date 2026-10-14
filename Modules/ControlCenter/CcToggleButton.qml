import QtQuick
import qs.Commons
import qs.Widgets

// Control Center icon toggle: a cut square, primary-filled when active.
// Inactive sits one step above the card so it doesn't read as a bare icon.
Item {
  id: root

  property bool active: false
  property bool available: true
  default property alias content: contentItem.data
  signal tapped

  implicitWidth: 40
  implicitHeight: 40

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferIcon
    cutTopRight: true
    cutBottomLeft: true
    fillColor: root.active ? (hover.hovered ? Qt.lighter(Colors.primary, 1.08) : Colors.primary) : (hover.hovered ? Colors.alpha(Colors.primary, 0.18) : Colors.surfaceContainerHigh)
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
