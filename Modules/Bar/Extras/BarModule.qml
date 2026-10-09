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
  // Mirrors the two chamfered corners — see crux skill's notes.md.
  property bool invertChamfer: false

  // Vertical bar: fixed cross-axis (matches the module's usual 30px
  // thickness), content-driven length instead of the other way around —
  // same swap Clock.qml/Workspaces.qml already do internally, just hoisted
  // to the shared container so every module gets it for free.
  implicitHeight: root.vertical ? (contentRow.implicitHeight + topPadding + bottomPadding) : Tokens.barModuleHeight
  implicitWidth: root.vertical ? Tokens.barModuleHeight : (contentRow.implicitWidth + leftPadding + rightPadding)
  height: implicitHeight
  width: implicitWidth

  // Picks user-configurable opacity source; was hardcoded before, making both sliders no-ops.
  readonly property real effectiveOpacity: Settings.data.bar.useSeparateOpacity ? Settings.data.bar.backgroundOpacity : Settings.data.theme.barOpacity

  // Grouped sections draw one surface for the whole section, so a module
  // inside one carries no chamfer, stroke or rim of its own — only its
  // hover state.
  readonly property bool grouped: Settings.isLoaded && Settings.data.bar.groupSections

  Chamfer {
    anchors.fill: parent
    visible: !root.grouped
    chamferSize: Tokens.chamferModule
    cutTopLeft: root.invertChamfer
    cutBottomRight: root.invertChamfer
    cutTopRight: !root.invertChamfer
    cutBottomLeft: !root.invertChamfer
    fillColor: Colors.alpha(root.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer, root.effectiveOpacity)
    strokeColor: Colors.outlineVariant
    strokeWidth: Tokens.borderModule
    // Rim only: the bar window is exactly the bar's thickness, so a
    // shadow has nowhere to fall.
    rimLight: true
    rimOpacity: Tokens.rimOpacityCard
  }

  // Hover feedback for the grouped case, where the chamfer above is gone.
  Chamfer {
    anchors.fill: parent
    visible: root.grouped
    chamferSize: Tokens.chamferIcon
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
