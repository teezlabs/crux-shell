import QtQuick
import qs.Commons

// Flat track, primary fill and a tick thumb; continuous, since settings ranges don't suit SegMeter cells.
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
    color: Colors.surfaceContainerHigh
    border.color: Colors.outline
    border.width: Tokens.borderModule

    Rectangle {
      width: parent.width * root._ratio
      height: parent.height
      color: Colors.primary
    }
  }

  Rectangle {
    id: thumb
    width: 2
    height: 14
    anchors.verticalCenter: parent.verticalCenter
    x: root._ratio * (root.width - width)
    color: Colors.primary
  }

  MouseArea {
    anchors.fill: parent
    anchors.margins: -4
    cursorShape: Qt.PointingHandCursor
    // Keeps an ancestor Flickable from stealing a slightly diagonal drag.
    preventStealing: true
    onPressed: mouse => root._setFromX(mouse.x - 4)
    onPositionChanged: mouse => {
      if (pressed)
        root._setFromX(mouse.x - 4);
    }
  }
}
