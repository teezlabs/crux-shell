import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Control Center VOL/BRI slider row: label gutter + continuous slider +
// value column. The panel follows the reference look rather than the
// spec's segmented meter — see CcLevelSlider.qml.
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

  CcLevelSlider {
    Layout.fillWidth: true
    value: root.value
    onMoved: pct => root.moved(pct)
  }

  NText {
    Layout.preferredWidth: 26
    horizontalAlignment: Text.AlignRight
    text: String(Math.round(root.value))
    color: Color.surfaceText
  }
}
