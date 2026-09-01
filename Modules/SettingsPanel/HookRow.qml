import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras

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

    Text {
      text: root.label
      color: root.value ? Color.surfaceText : Color.surfaceTextMuted
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.bodySmSize
      font.weight: Font.DemiBold
    }

    Text {
      text: root.description
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.captionSize
      font.letterSpacing: Tokens.captionSize * Tokens.captionTracking
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    Text {
      visible: root.value !== ""
      text: root.value
      color: Color.primary
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.captionSize
      elide: Text.ElideMiddle
      Layout.fillWidth: true
    }
  }

  Item {
    width: 48
    height: 26

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferIcon
      cutTopRight: true
      cutBottomLeft: true
      fillColor: editHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer
      strokeColor: Color.outline
      strokeWidth: Tokens.borderModule
    }

    Text {
      anchors.centerIn: parent
      text: root.value ? "EDIT" : "SET"
      color: Color.surfaceText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelXsSize
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
    }

    HoverHandler {
      id: editHover
      cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
      onTapped: root.editClicked()
    }
  }
}
