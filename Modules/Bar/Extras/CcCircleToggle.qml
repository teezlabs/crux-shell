import QtQuick
import qs.Commons

// Circular icon toggle for Control Center's top row — deliberate one-off departure from the app's "no radius" rule.
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
    color: root.active ? Color.primary : Color.surfaceContainer
    opacity: root.available ? 1 : 0.4
  }

  Item {
    id: contentItem
    anchors.fill: parent
  }

  HoverHandler {
    enabled: root.available
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    enabled: root.available
    onTapped: root.tapped()
  }
}
