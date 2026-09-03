import QtQuick
import qs.Commons

// Circular icon toggle for Control Center's top row — deliberate one-off
// departure from the app's "no radius" rule.
//
// The inactive fill is one step above the card it sits on, not
// surfaceContainer: once each section became its own surfaceContainer card,
// an inactive toggle painted the same colour as its background and read as
// a bare floating icon.
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
    color: root.active ? Color.primary : (hover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainerLow)
    border.color: root.active ? "transparent" : Color.outlineVariant
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
