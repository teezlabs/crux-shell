import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// One Control Center section as its own chamfered card. Height comes from
// the inner ColumnLayout, not the wrapper — an Item doesn't inherit
// implicitHeight from its children.
Item {
  id: root

  property real padding: 12
  property real spacing: 8
  default property alias content: inner.data

  Layout.fillWidth: true
  implicitHeight: inner.implicitHeight + root.padding * 2

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
    anchors.margins: root.padding
    spacing: root.spacing
  }
}
