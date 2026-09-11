import QtQuick
import qs.Commons

// Media player transport cell (§6.6): 5-cell strip, 1px gaps, on surface.
// The active cell (play/pause when playing, shuffle/loop when toggled on)
// gets primaryContainer fill + primary glyph. `available: false` (the
// player doesn't support this control) dims it and blocks taps.
Item {
  id: root

  property string glyph: ""
  property bool active: false
  property bool available: true
  signal tapped

  implicitHeight: 36

  Rectangle {
    anchors.fill: parent
    color: root.active ? Color.primaryContainer : Color.surface
    opacity: root.available ? 1 : 0.35
  }

  Text {
    anchors.centerIn: parent
    text: root.glyph
    color: root.active ? Color.primary : Color.surfaceText
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
