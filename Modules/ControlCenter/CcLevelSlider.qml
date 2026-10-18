import QtQuick
import qs.Commons
import qs.Widgets

// Continuous round-thumb slider for Control Center's volume and brightness; SegMeter stays everywhere else.
Item {
  id: root

  property real value: 0 // 0..100
  property bool interactive: true
  property color filledColor: Colors.primary
  property color trackColor: Colors.surfaceContainerHigh
  property real trackHeight: 4
  property real thumbRadius: 7

  signal moved(real pct)

  implicitHeight: root.thumbRadius * 2
  readonly property real ratio: Math.max(0, Math.min(1, root.value / 100))
  // Keep the thumb fully inside the item at both ends.
  readonly property real usable: Math.max(0, width - root.thumbRadius * 2)

  Rectangle {
    id: track
    anchors.verticalCenter: parent.verticalCenter
    x: 0
    width: parent.width
    height: root.trackHeight
    radius: height / 2
    color: root.trackColor
  }

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    x: 0
    width: root.thumbRadius + root.usable * root.ratio
    height: root.trackHeight
    radius: height / 2
    color: root.filledColor
    opacity: root.interactive ? 1 : 0.5
  }

  Rectangle {
    id: thumb
    anchors.verticalCenter: parent.verticalCenter
    x: root.usable * root.ratio
    width: root.thumbRadius * 2
    height: root.thumbRadius * 2
    radius: root.thumbRadius
    color: root.filledColor
    opacity: root.interactive ? 1 : 0.5
  }

  MouseArea {
    anchors.fill: parent
    anchors.margins: -4
    enabled: root.interactive
    cursorShape: Qt.PointingHandCursor
    // Keeps an ancestor Flickable from stealing a slightly diagonal drag.
    preventStealing: true

    function apply(mx) {
      const usable = root.usable;
      const pct = usable <= 0 ? 0 : Math.max(0, Math.min(1, (mx - 4 - root.thumbRadius) / usable));
      root.moved(pct * 100);
    }
    onPressed: mouse => apply(mouse.x)
    onPositionChanged: mouse => {
      if (pressed)
        apply(mouse.x);
    }
  }
}
