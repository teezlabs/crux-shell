import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Title and description on the left, the control on the right; rows after the first get a divider.
ColumnLayout {
  id: root

  property string label: ""
  property string description: ""
  default property alias content: contentRow.children

  // Set on completion: whether a sibling row sits above this one, and whether a control asked to fill.
  property bool _hasRowAbove: false
  property bool _controlFills: false

  spacing: 14
  Layout.fillWidth: true

  Rectangle {
    visible: root._hasRowAbove
    Layout.fillWidth: true
    Layout.preferredHeight: Tokens.borderDivider
    color: Colors.alpha(Colors.outline, 0.35)
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Tokens.spaceXl

    ColumnLayout {
      id: textCol
      visible: root.label !== "" || descSlot.children.length > 0 || root.description !== ""
      spacing: Tokens.spaceXs
      Layout.fillWidth: true
      Layout.preferredWidth: root._controlFills ? 220 : -1
      Layout.alignment: Qt.AlignVCenter

      NText {
        visible: root.label !== ""
        text: root.label
        color: Colors.surfaceText
        size: NText.Size.BodySm
        font.weight: Font.DemiBold
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        Layout.fillWidth: true
      }

      NText {
        visible: root.description !== ""
        text: root.description
        color: Colors.labelText
        size: NText.Size.Caption
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        Layout.fillWidth: true
      }

      ColumnLayout {
        id: descSlot
        visible: children.length > 0
        spacing: 0
        Layout.fillWidth: true
      }
    }

    RowLayout {
      id: contentRow
      spacing: Tokens.spaceMd
      Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
      Layout.fillWidth: root._controlFills || !textCol.visible
      Layout.preferredWidth: root._controlFills ? 320 : -1
    }
  }

  Component.onCompleted: {
    const kids = contentRow.children;
    // A trailing caption is the row's description and moves under the title; a BodySm one is a readout and stays.
    const last = kids.length >= 2 ? kids[kids.length - 1] : null;
    if (last && last.elide !== undefined && last.size === NText.Size.Caption) {
      last.parent = descSlot;
      last.Layout.fillWidth = true;
      last.wrapMode = Text.WordWrap;
      last.elide = Text.ElideNone;
    }
    // Layouts default fillWidth to true, so only a non-layout control that asked to fill counts.
    for (let i = 0; i < contentRow.children.length; i++) {
      const c = contentRow.children[i];
      if (c.Layout.fillWidth && c.layoutDirection === undefined)
        root._controlFills = true;
    }
    const siblings = root.parent ? root.parent.children : [];
    for (let i = 0; i < siblings.length && siblings[i] !== root; i++)
      if (siblings[i].label !== undefined && siblings[i].content !== undefined)
        root._hasRowAbove = true;
  }
}
