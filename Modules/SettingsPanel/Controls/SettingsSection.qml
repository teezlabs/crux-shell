import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras

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

    Text {
      text: root.title.toUpperCase()
      color: Color.surfaceText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelSize
      font.weight: Font.DemiBold
      font.letterSpacing: Tokens.labelSize * Tokens.labelTracking
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: Tokens.borderDivider
      color: Color.surfaceContainerHigh
    }
  }

  Text {
    visible: root.description !== ""
    text: root.description
    color: Color.labelText
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.captionSize
    font.letterSpacing: Tokens.captionSize * Tokens.captionTracking
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
