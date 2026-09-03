import QtQuick
import QtQuick.Layouts
import qs.Commons

// NSlider plus a right-aligned readout of its current value, the shape
// almost every settings slider actually wants.
//
// `readoutText` takes the caller's own expression verbatim, so migrating a
// hand-rolled slider+label pair doesn't require rewriting the label into a
// function of the slider value — the two aren't always the same thing.
// `format` is the fallback when no explicit text is given.
RowLayout {
  id: root

  property real from: 0
  property real to: 1
  property real value: 0
  property real stepSize: 0
  property var format: v => String(Math.round(v))
  property string readoutText: ""
  // 0 lets the slider fill the row; anything else pins it, matching the
  // fixed widths the settings rows were laid out with.
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
    color: Color.labelText
  }
}
