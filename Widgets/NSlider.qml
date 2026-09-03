import QtQuick
import qs.Commons

// v2-styled slider: flat track (radius: 0 per hard rule 1), primary fill,
// a thin tick instead of a circular thumb — kept continuous rather than
// discretized into SegMeter cells, since settings sliders cover arbitrary
// ranges (font size, opacity, spacing) a fixed cell count wouldn't suit.
Item {
  id: root

  property real from: 0
  property real to: 1
  property real value: 0
  property real stepSize: 0
  signal moved(real value)

  implicitWidth: 200
  implicitHeight: 18

  readonly property real _ratio: root.to > root.from ? Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from))) : 0

  function _setFromX(x) {
    var ratio = Math.max(0, Math.min(1, x / root.width));
    var raw = root.from + ratio * (root.to - root.from);
    if (root.stepSize > 0)
      raw = Math.round(raw / root.stepSize) * root.stepSize;
    raw = Math.max(root.from, Math.min(root.to, raw));
    root.value = raw;
    root.moved(raw);
  }

  Rectangle {
    id: track
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 4
    color: Color.surfaceContainerHigh
    border.color: Color.outline
    border.width: Tokens.borderModule

    Rectangle {
      width: parent.width * root._ratio
      height: parent.height
      color: Color.primary
    }
  }

  Rectangle {
    id: thumb
    width: 2
    height: 14
    anchors.verticalCenter: parent.verticalCenter
    x: root._ratio * (root.width - width)
    color: Color.primary
  }

  MouseArea {
    anchors.fill: parent
    anchors.margins: -4
    cursorShape: Qt.PointingHandCursor
    // Without this, a slightly-off-horizontal drag lets the ancestor
    // Flickable steal the grab and scroll the tab instead of dragging.
    preventStealing: true
    onPressed: mouse => root._setFromX(mouse.x - 4)
    onPositionChanged: mouse => {
      if (pressed)
        root._setFromX(mouse.x - 4);
    }
  }
}
