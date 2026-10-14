import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// One Control Center section as its own card. Height comes from
// the inner ColumnLayout, not the wrapper — an Item doesn't inherit
// implicitHeight from its children.
Item {
  id: root

  property real padding: Tokens.spaceLg
  property real spacing: Tokens.spaceMd
  default property alias content: inner.data

  Layout.fillWidth: true
  implicitHeight: inner.implicitHeight + root.padding * 2

  // Inner surface: square and fill-only — chamfers are for outer shapes.
  Chamfer {
    anchors.fill: parent
    fillColor: Colors.surfaceContainer
  }

  ColumnLayout {
    id: inner
    anchors.fill: parent
    anchors.margins: root.padding
    spacing: root.spacing
  }
}
