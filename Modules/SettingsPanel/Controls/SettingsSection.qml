import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// Grouped-card section wrapper, v2 style: chamfered card (radius: 0, no
// gradient/glow per hard rules 1/4), accent tick + uppercase label-tier
// title — same visual language as every other panel's section headers.
ColumnLayout {
  id: root

  property string title: ""
  property string description: ""
  default property alias content: inner.children

  spacing: 8
  Layout.fillWidth: true

  RowLayout {
    visible: root.title !== ""
    spacing: 8
    Layout.bottomMargin: 2

    Rectangle {
      width: 3
      height: 12
      color: Color.primary
    }

    NText {
      tracking: true
      text: root.title.toUpperCase()
      color: Color.surfaceText
      size: NText.Size.Label
      font.weight: Font.DemiBold
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: Tokens.borderDivider
      color: Color.surfaceContainerHigh
    }
  }

  NText {
    tracking: true
    visible: root.description !== ""
    text: root.description
    color: Color.labelText
    size: NText.Size.Caption
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    Layout.bottomMargin: 4
  }

  Item {
    Layout.fillWidth: true
    Layout.preferredHeight: inner.implicitHeight + 26

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferModule
      cutTopRight: true
      cutBottomLeft: true
      fillColor: Color.surfaceContainer
      strokeColor: Color.outline
      strokeWidth: Tokens.borderModule
    }

    ColumnLayout {
      id: inner
      anchors.fill: parent
      anchors.margins: 14
      spacing: 14
    }
  }
}
