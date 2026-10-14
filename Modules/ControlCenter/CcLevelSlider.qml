import QtQuick
import qs.Commons
import qs.Widgets

// Control Center level control: the shell's segmented meter, draggable.
Item {
  id: root

  property real value: 0 // 0..100
  property bool interactive: true
  property color filledColor: Colors.primary
  property color trackColor: Colors.surfaceContainerHigh

  signal moved(real pct)

  implicitHeight: meter.implicitHeight

  SegMeter {
    id: meter
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    cellCount: Tokens.meterControlCenterCells
    cellHeight: Tokens.meterControlCenterCellHeight
    value: root.value
    interactive: root.interactive
    filledColor: root.filledColor
    emptyColor: root.trackColor
    onMoved: v => root.moved(v)
  }
}
