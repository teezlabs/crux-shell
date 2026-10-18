import QtQuick
import qs.Commons
import qs.Widgets

// "LABEL value" pair (§3: status is text, not glyphs), e.g. "VOL 62".
Row {
  id: root

  property string label: ""
  property string value: ""
  property color valueColor: Colors.surfaceText
  spacing: 5

  NText {
    tracking: true
    text: root.label.toUpperCase()
    color: Colors.labelText
    size: NText.Size.LabelXs
    anchors.verticalCenter: parent.verticalCenter
  }

  NText {
    tracking: true
    text: root.value
    color: root.valueColor
    size: NText.Size.Caption
    anchors.verticalCenter: parent.verticalCenter
  }
}
