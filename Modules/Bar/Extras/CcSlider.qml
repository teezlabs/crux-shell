import QtQuick
import QtQuick.Layouts
import qs.Commons

// Control Center VOL/BRI slider row (§6.3): label gutter + 16-cell
// interactive meter + value column.
RowLayout {
  id: root

  property string label: ""
  property real value: 0 // 0..100
  signal moved(real pct)

  spacing: 10
  Layout.preferredHeight: 28

  Text {
    Layout.preferredWidth: 32
    text: root.label
    color: Color.labelText
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.labelSize
    font.weight: Font.DemiBold
    font.letterSpacing: Tokens.labelSize * Tokens.labelTracking
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

  Text {
    Layout.preferredWidth: 26
    horizontalAlignment: Text.AlignRight
    text: String(Math.round(root.value))
    color: Color.surfaceText
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.bodySize
  }
}
