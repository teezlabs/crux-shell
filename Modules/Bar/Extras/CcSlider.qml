import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Control Center VOL/BRI slider row (§6.3): label gutter + 16-cell
// interactive meter + value column.
RowLayout {
  id: root

  property string label: ""
  property real value: 0 // 0..100
  signal moved(real pct)

  spacing: 10
  Layout.preferredHeight: 28

  NText {
    tracking: true
    Layout.preferredWidth: 32
    text: root.label
    color: Color.labelText
    size: NText.Size.Label
    font.weight: Font.DemiBold
  }

  SegMeter {
    Layout.fillWidth: true
    Layout.preferredHeight: Tokens.meterControlCenterCellHeight
    cellCount: Tokens.meterControlCenterCells
    cellHeight: Tokens.meterControlCenterCellHeight
    value: root.value
    interactive: true
    filledColor: Color.primary
    emptyColor: Color.surfaceContainerHigh
    onMoved: pct => root.moved(pct)
  }

  NText {
    Layout.preferredWidth: 26
    horizontalAlignment: Text.AlignRight
    text: String(Math.round(root.value))
    color: Color.surfaceText
  }
}
