import QtQuick
import qs.Commons

// "LABEL value" pair — §3: "Status is text, not glyphs." e.g. "NET WLAN",
// "VOL 62", "BAT 87". Label in label-xs grey (uppercase), value in caption
// on_surface.
Row {
  id: root

  property string label: ""
  property string value: ""
  property color valueColor: Color.surfaceText
  spacing: 5

  Text {
    text: root.label.toUpperCase()
    color: Color.labelText
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.labelXsSize
    font.weight: Tokens.labelXsWeight
    font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
    anchors.verticalCenter: parent.verticalCenter
  }

  Text {
    text: root.value
    color: root.valueColor
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.captionSize
    font.letterSpacing: Tokens.captionSize * Tokens.captionTracking
    anchors.verticalCenter: parent.verticalCenter
  }
}
