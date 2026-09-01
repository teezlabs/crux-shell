import QtQuick
import qs.Commons

// Shared chamfered card background for a floating panel. Backdrop blur is wired separately at the PanelWindow level.
Item {
  id: root

  default property alias content: contentItem.children
  property bool cutTopLeft: false
  property bool cutTopRight: false
  property bool cutBottomLeft: false
  property bool cutBottomRight: false

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferPanel
    cutTopLeft: root.cutTopLeft
    cutTopRight: root.cutTopRight
    cutBottomLeft: root.cutBottomLeft
    cutBottomRight: root.cutBottomRight
    fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
    strokeColor: Color.outline
    strokeWidth: Tokens.borderPanel
  }

  Item {
    id: contentItem
    anchors.fill: parent
  }
}
