import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// One hook entry: label + command preview + EDIT/SET button (opens HookEditPopup).
RowLayout {
  id: root

  property string label: ""
  property string description: ""
  property string value: ""

  signal editClicked

  spacing: 10
  Layout.fillWidth: true

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 2

    NText {
      text: root.label
      color: root.value ? Color.surfaceText : Color.surfaceTextMuted
      size: NText.Size.BodySm
      font.weight: Font.DemiBold
    }

    NText {
      tracking: true
      text: root.description
      color: Color.labelText
      size: NText.Size.Caption
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    NText {
      visible: root.value !== ""
      text: root.value
      color: Color.primary
      size: NText.Size.Caption
      elide: Text.ElideMiddle
      Layout.fillWidth: true
    }
  }

  NButton {
    height: 26
    implicitWidth: 48
    text: root.value ? "EDIT" : "SET"
    textSize: NText.Size.LabelXs
    onClicked: root.editClicked()
  }
}
