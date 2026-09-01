import QtQuick
import QtQuick.Layouts
import qs.Commons

// Control Center telemetry row (§6.3): label gutter + 18-cell read-only
// meter + value column. TEMP uses tertiary fill instead of primary (§5:
// "TEMP fills with tertiary, not primary").
RowLayout {
  id: root

  property string label: ""
  property string value: ""
  property real percent: 0
  property color filledColor: Color.primary

  spacing: 10
  Layout.preferredHeight: 14

  Text {
    Layout.preferredWidth: 36
    text: root.label
    color: Color.labelText
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.labelXsSize
    font.weight: Font.DemiBold
    font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
  }

  SegMeter {
    Layout.fillWidth: true
    Layout.preferredHeight: Tokens.meterTelemetryCellHeight
    cellCount: Tokens.meterTelemetryCells
    cellHeight: Tokens.meterTelemetryCellHeight
    value: root.percent
    interactive: false
    filledColor: root.filledColor
    emptyColor: Color.surfaceContainerHigh
  }

  Text {
    Layout.preferredWidth: 44
    horizontalAlignment: Text.AlignRight
    text: root.value
    color: Color.surfaceText
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.bodySmSize
  }
}
