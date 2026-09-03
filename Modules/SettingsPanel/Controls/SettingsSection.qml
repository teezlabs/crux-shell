import QtQuick
import QtQuick.Layouts
import qs.Commons
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

    NDivider {
      Layout.fillWidth: true
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

  NBox {
    Layout.fillWidth: true
    // 26 rather than the box's own 28px of padding: the card has always
    // been 2px tighter than its margins, keep it that way.
    Layout.preferredHeight: inner.implicitHeight + 26

    ColumnLayout {
      id: inner
      anchors.fill: parent
      spacing: 14
    }
  }
}
