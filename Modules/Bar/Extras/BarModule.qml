import QtQuick
import qs.Commons

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

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferModule
    cutTopLeft: root.invertChamfer
    cutBottomRight: root.invertChamfer
    cutTopRight: !root.invertChamfer
    cutBottomLeft: !root.invertChamfer
    fillColor: Color.alpha(root.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer, root.effectiveOpacity)
    strokeColor: Color.outlineVariant
    strokeWidth: Tokens.borderModule
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
