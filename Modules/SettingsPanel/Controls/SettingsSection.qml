import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Section card: chamfered, with an accent tick and an uppercase title.
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
      color: Colors.primary
    }

    NText {
      tracking: true
      text: root.title.toUpperCase()
      color: Colors.surfaceText
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
    color: Colors.labelText
    size: NText.Size.Caption
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
    Layout.bottomMargin: 4
  }

  NBox {
    Layout.fillWidth: true
    // 26, not the box's 28px padding: the card has always sat 2px tighter.
    Layout.preferredHeight: inner.implicitHeight + 26

    ColumnLayout {
      id: inner
      anchors.fill: parent
      spacing: 14
    }
  }
}
