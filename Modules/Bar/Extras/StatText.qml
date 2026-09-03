import QtQuick
import qs.Commons
import qs.Widgets

// "LABEL value" pair — §3: "Status is text, not glyphs." e.g. "NET WLAN",
// "VOL 62", "BAT 87". Label in label-xs grey (uppercase), value in caption
// on_surface.
Row {
  id: root

  property string label: ""
  property string value: ""
  property color valueColor: Color.surfaceText
  spacing: 5

  NText {
    tracking: true
    text: root.label.toUpperCase()
    color: Color.labelText
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
