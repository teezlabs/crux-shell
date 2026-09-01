import QtQuick
import qs.Commons

// Shared chamfered card background for a floating panel (launcher, control
// center, sidebar, media popover, calendar, ...) — §4: 1px outline border,
// §1: panelOpacity (0.95) fill. Actual backdrop blur is wired at the
// PanelWindow level per panel (BackgroundEffect.blurRegion, same mechanism
// noctalia's MainScreen.qml uses) since it's a window-level compositor
// effect, not something a background Rectangle can do on its own — this
// component is just the visible card, not the blur.
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
