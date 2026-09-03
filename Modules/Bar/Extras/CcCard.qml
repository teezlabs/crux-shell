import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// One Control Center section, as its own chamfered card.
//
// The panel used to be a single slab with hairline rules between sections;
// this gives each section its own surface with gaps between them, which is
// the grouping noctalia's control center uses. Corners stay chamfered —
// only the layout is borrowed.
//
// Height is driven off the inner ColumnLayout rather than the wrapper,
// because an Item doesn't take implicitHeight from its children and would
// collapse to nothing inside a ColumnLayout.
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
