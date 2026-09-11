import QtQuick
import qs.Commons

// Segmented meter: discrete cells, filled = round(value / 100 * cellCount). interactive:true also accepts drag/tap to set value.
Item {
  id: root

  property real value: 0 // 0..100
  property int cellCount: 18
  property int cellHeight: 5
  property color filledColor: Color.primary
  property color emptyColor: Color.surfaceContainerHigh
  property bool interactive: false
  signal moved(real value)

  implicitHeight: cellHeight

  readonly property int _filled: Math.round(Math.max(0, Math.min(100, root.value)) / 100 * root.cellCount)

  function _setFromX(x) {
    if (!root.interactive)
      return;
    var ratio = Math.max(0, Math.min(1, x / root.width));
    root.moved(ratio * 100);
  }

  Row {
    anchors.fill: parent
    spacing: Tokens.meterCellSpacing

    Repeater {
      model: root.cellCount

      delegate: Rectangle {
        required property int index
        width: (root.width - (root.cellCount - 1) * Tokens.meterCellSpacing) / root.cellCount
        height: root.cellHeight
        color: index < root._filled ? root.filledColor : root.emptyColor

        Behavior on color {
          ColorAnimation {
            duration: Tokens.durationMeterFill
            easing.type: Tokens.easingMeterFill
          }
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    anchors.margins: root.interactive ? -6 : 0
    enabled: root.interactive
    cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    onPressed: mouse => root._setFromX(mouse.x - (root.interactive ? 6 : 0))
    onPositionChanged: mouse => {
      if (pressed)
        root._setFromX(mouse.x - (root.interactive ? 6 : 0));
    }
  }
}
