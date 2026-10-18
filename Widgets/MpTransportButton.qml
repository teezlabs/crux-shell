import QtQuick
import qs.Commons

// Media transport cell (§6.6); the active one is filled, `available: false` dims it and blocks taps.
Item {
  id: root

  property string glyph: ""
  property bool active: false
  property bool available: true
  signal tapped

  implicitHeight: 36

  Rectangle {
    anchors.fill: parent
    color: root.active ? Colors.primaryContainer : Colors.surface
    opacity: root.available ? 1 : 0.35
  }

  Text {
    anchors.centerIn: parent
    text: root.glyph
    color: root.active ? Colors.primary : Colors.surfaceText
    font.pixelSize: 14
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
