import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// A chamfered group of network or device rows: a tracked label with optional trailing controls, then the rows.
// `active` lights the outline, for the card holding the live connection.
Item {
  id: root

  property string label: ""
  property bool active: false
  default property alias content: body.data
  property alias trailing: trail.data

  Layout.fillWidth: true
  implicitHeight: col.implicitHeight + Tokens.spaceMd * 2

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferModule
    cutTopRight: true
    cutBottomLeft: true
    fillColor: root.active ? Colors.alpha(Colors.primary, 0.07) : Colors.surfaceContainer
    strokeColor: root.active ? Colors.alpha(Colors.primary, 0.5) : Colors.outlineVariant
    strokeWidth: Tokens.borderModule
  }

  ColumnLayout {
    id: col
    anchors.fill: parent
    anchors.margins: Tokens.spaceMd
    spacing: Tokens.spaceXs

    RowLayout {
      visible: root.label !== "" || trail.children.length > 0
      Layout.fillWidth: true
      Layout.leftMargin: Tokens.spaceXs
      Layout.bottomMargin: Tokens.spaceXs
      spacing: Tokens.spaceSm

      NText {
        Layout.fillWidth: true
        text: root.label
        tracking: true
        size: NText.Size.LabelXs
        font.weight: Font.DemiBold
        color: root.active ? Colors.primary : Colors.labelText
      }
      Row {
        id: trail
        spacing: Tokens.spaceSm
      }
    }

    ColumnLayout {
      id: body
      Layout.fillWidth: true
      spacing: Tokens.spaceXs
    }
  }
}
