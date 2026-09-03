import QtQuick
import QtQuick.Layouts
import qs.Commons

// NSlider plus a right-aligned readout of its current value, the shape
// almost every settings slider actually wants.
RowLayout {
  id: root

  property real from: 0
  property real to: 1
  property real value: 0
  property real stepSize: 0
  // Called with the value to render the readout; defaults to a rounded number.
  property var format: v => String(Math.round(v))
  property real readoutWidth: 46

  signal moved(real value)

  spacing: 10

  NSlider {
    id: slider
    Layout.fillWidth: true
    from: root.from
    to: root.to
    value: root.value
    stepSize: root.stepSize
    onMoved: v => {
      root.value = v;
      root.moved(v);
    }
  }

  NText {
    Layout.preferredWidth: root.readoutWidth
    horizontalAlignment: Text.AlignRight
    text: root.format(root.value)
    size: NText.Size.BodySm
    mono: true
    color: Color.labelText
  }
}
