import QtQuick
import QtQuick.Layouts
import qs.Commons

// Panel/page heading: accent title over an optional description.
ColumnLayout {
  id: root

  property string label: ""
  property string description: ""

  opacity: enabled ? 1.0 : 0.6
  spacing: 2
  Layout.fillWidth: true

  NText {
    visible: root.label !== ""
    text: root.label
    size: NText.Size.BodyLg
    font.weight: Font.DemiBold
    color: Color.primary
    Layout.fillWidth: true
  }

  NText {
    visible: root.description !== ""
    text: root.description
    size: NText.Size.Caption
    color: Color.labelText
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }
}
