import QtQuick
import QtQuick.Layouts
import qs.Commons

// NSlider plus a right-aligned readout; readoutText is taken verbatim, format is the fallback.
RowLayout {
  id: root

  property real from: 0
  property real to: 1
  property real value: 0
  property real stepSize: 0
  property var format: v => String(Math.round(v))
  property string readoutText: ""
  // 0 fills the row; anything else pins the slider width.
  property real sliderWidth: 0
  property real readoutWidth: 0

  signal moved(real value)

  spacing: 10

  NSlider {
    id: slider
    Layout.fillWidth: root.sliderWidth <= 0
    Layout.preferredWidth: root.sliderWidth > 0 ? root.sliderWidth : implicitWidth
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
    Layout.preferredWidth: root.readoutWidth > 0 ? root.readoutWidth : implicitWidth
    text: root.readoutText !== "" ? root.readoutText : root.format(root.value)
    size: NText.Size.BodySm
    color: Colors.labelText
  }
}
