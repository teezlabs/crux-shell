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
  readonly property bool inputFocused: input.activeFocus
  property bool mono: false
  // Overrides the token family — used by the font-picker fields, which
  // render their own value as a live preview.
  property string fontFamily: ""
  property color fillColor: Color.surface
  property real horizontalPadding: 8

  signal editingFinished
  signal accepted
  signal textEdited(string text)

  implicitWidth: 200
  implicitHeight: 28
  opacity: enabled ? 1.0 : 0.5

  function forceFocus(): void {
    input.forceActiveFocus();
  }

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferIcon
    cutTopRight: true
    cutBottomLeft: true
    fillColor: root.fillColor
    strokeColor: input.activeFocus ? Color.primary : Color.outline
    strokeWidth: Tokens.borderModule
  }

  NText {
    id: placeholder
    anchors.fill: input
    visible: input.text === "" && !input.activeFocus
    size: NText.Size.BodySm
    mono: root.mono
    color: Color.disabledText
    verticalAlignment: Text.AlignVCenter
  }

  TextInput {
    id: input
    anchors.fill: parent
    anchors.leftMargin: root.horizontalPadding
    anchors.rightMargin: root.horizontalPadding
    verticalAlignment: TextInput.AlignVCenter
    clip: true
    color: Color.surfaceText
    selectionColor: Color.primaryContainer
    selectedTextColor: Color.primaryContainerText
    font.family: root.fontFamily !== "" ? root.fontFamily : (root.mono ? Tokens.monoFontFamily : Tokens.fontFamily)
    font.pixelSize: Tokens.bodySmSize
    selectByMouse: true
    onEditingFinished: root.editingFinished()
    onAccepted: root.accepted()
    onTextEdited: root.textEdited(text)
  }
}
