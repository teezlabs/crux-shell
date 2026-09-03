import QtQuick
import qs.Commons

// Chamfered single-line text field.
Item {
  id: root

  property alias text: input.text
  property alias placeholderText: placeholder.text
  property alias readOnly: input.readOnly
  property alias echoMode: input.echoMode
  property alias inputItem: input
  property bool mono: false

  signal editingFinished
  signal accepted

  implicitWidth: 200
  implicitHeight: 28
  opacity: enabled ? 1.0 : 0.5

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferIcon
    cutTopRight: true
    cutBottomLeft: true
    fillColor: Color.surfaceContainerHigh
    strokeColor: input.activeFocus ? Color.primary : Color.outline
    strokeWidth: Tokens.borderModule
  }

  NText {
    id: placeholder
    anchors.fill: input
    visible: input.text === ""
    size: NText.Size.BodySm
    color: Color.disabledText
    verticalAlignment: Text.AlignVCenter
  }

  TextInput {
    id: input
    anchors.fill: parent
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    verticalAlignment: TextInput.AlignVCenter
    clip: true
    color: Color.surfaceText
    selectionColor: Color.primaryContainer
    selectedTextColor: Color.primaryContainerText
    font.family: root.mono ? Tokens.monoFontFamily : Tokens.fontFamily
    font.pixelSize: Tokens.bodySmSize
    selectByMouse: true
    onEditingFinished: root.editingFinished()
    onAccepted: root.accepted()
  }
}
