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

    NText {
      tracking: true
      anchors.centerIn: parent
      text: root.value ? "EDIT" : "SET"
      color: Color.surfaceText
      size: NText.Size.LabelXs
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
