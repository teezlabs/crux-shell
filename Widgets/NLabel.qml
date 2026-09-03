import QtQuick
import QtQuick.Layouts
import qs.Commons

// Field label with an optional description underneath — the left half of
// a settings row.
ColumnLayout {
  id: root

  property string label: ""
  property string description: ""
  property color labelColor: Color.surfaceText
  property color descriptionColor: Color.labelText

  opacity: enabled ? 1.0 : 0.6
  spacing: 2
  visible: root.label !== "" || root.description !== ""

  NText {
    visible: root.label !== ""
    text: root.label
    size: NText.Size.BodySm
    color: root.labelColor
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  NText {
    visible: root.description !== ""
    text: root.description
    size: NText.Size.Caption
    color: root.descriptionColor
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }
}
