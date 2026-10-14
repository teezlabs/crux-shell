import QtQuick
import qs.Commons
import qs.Widgets

// Label, value and a short segmented meter — the square stand-in for a
// circular gauge. Same properties as CircularGauge.
Item {
  id: root

  property real percent: 0 // 0..100
  property color fillColor: Colors.primary
  property color trackColor: Colors.surfaceContainerHigh
  property string value: ""
  property string label: ""

  implicitWidth: 64
  implicitHeight: col.implicitHeight
  width: implicitWidth
  height: implicitHeight

  Column {
    id: col
    width: parent.width
    spacing: Tokens.spaceXs

    NText {
      tracking: true
      text: root.label
      color: Colors.labelText
      size: NText.Size.LabelXs
    }
    NText {
      text: root.value
      color: Colors.surfaceText
      size: NText.Size.BodyLg
      font.weight: Font.Medium
    }
    SegMeter {
      width: parent.width
      cellCount: 8
      cellHeight: 4
      value: root.percent
      filledColor: root.fillColor
      emptyColor: root.trackColor
    }
  }
}
