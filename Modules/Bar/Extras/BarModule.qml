import QtQuick
import qs.Commons
import qs.Widgets

// Shared chamfered container for a detached bar module. Chamfers two opposite corners; no hover transition.
Item {
  id: root

  default property alias content: contentRow.children
  property bool hoverable: true
  property bool hovered: false
  property bool vertical: false
  property real leftPadding: 10
  property real rightPadding: 10
  property real topPadding: 6
  property real bottomPadding: 6
  // Mirrors the two chamfered corners (docs/design-notes.md, "Chamfer inversion accent").
  property bool invertChamfer: false

  // Vertical bar: fixed cross-axis, content-driven length.
  implicitHeight: root.vertical ? (contentRow.implicitHeight + topPadding + bottomPadding) : Tokens.barModuleHeight
  implicitWidth: root.vertical ? Tokens.barModuleHeight : (contentRow.implicitWidth + leftPadding + rightPadding)
  height: implicitHeight
  width: implicitWidth

  // In a grouped section the section draws the surface; a module keeps only its hover state.
  readonly property bool grouped: Settings.isLoaded && Settings.data.bar.groupSections

  Chamfer {
    anchors.fill: parent
    visible: !root.grouped
    chamferSize: Tokens.chamferModule
    cutTopLeft: root.invertChamfer
    cutBottomRight: root.invertChamfer
    cutTopRight: !root.invertChamfer
    cutBottomLeft: !root.invertChamfer
    fillColor: Colors.alpha(root.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer, Tokens.barModuleAlpha)
    strokeColor: Colors.outlineVariant
    strokeWidth: Tokens.borderModule
    // Rim only: the bar window is exactly the bar's thickness, so a shadow has nowhere to fall.
    rimLight: true
    rimOpacity: Tokens.rimOpacityCard
  }

  // Hover feedback for the grouped case, where the chamfer above is gone.
  Chamfer {
    anchors.fill: parent
    visible: root.grouped
    chamferSize: Tokens.chamferGroupedCell
    cutTopLeft: root.invertChamfer
    cutBottomRight: root.invertChamfer
    cutTopRight: !root.invertChamfer
    cutBottomLeft: !root.invertChamfer
    fillColor: Colors.alpha(Colors.primary, root.hovered ? 0.16 : 0)
    strokeWidth: 0
  }

  Row {
    id: contentRow
    anchors.centerIn: parent
    spacing: 6
  }

  HoverHandler {
    enabled: root.hoverable
    onHoveredChanged: root.hovered = hovered
  }
}
