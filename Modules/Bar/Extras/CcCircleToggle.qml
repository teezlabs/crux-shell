import QtQuick
import qs.Commons

// Circular icon toggle for the Control Center's top row — explicitly
// requested to match a specific reference look, a deliberate one-off
// departure from the rest of the app's "no radius" rule, scoped to this
// one panel. Content (a Canvas glyph) is the default property, same
// pattern BarIconButton.qml uses.
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
