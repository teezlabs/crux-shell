import QtQuick
import qs.Commons
import qs.Widgets

// Shared chamfered-cell chrome for single-icon bar modules; glyph content is the default property.
Item {
  id: root

  property bool attention: false
  // Mirrors the two chamfered corners — see crux skill's notes.md.
  property bool invertChamfer: false
  default property alias content: contentItem.data
  signal tapped
  signal secondaryTapped

  implicitWidth: 32
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  // Same user-configurable opacity BarModule.qml reads — see its own
  // comment for the bug this fixes (was hardcoded to Tokens.barModuleOpacity,
  // so neither Settings opacity slider ever did anything here either).
  readonly property real effectiveOpacity: Settings.data.bar.useSeparateOpacity ? Settings.data.bar.backgroundOpacity : Settings.data.theme.barOpacity

  // Inside a grouped section the section itself carries the surface, so
  // this one keeps only hover and the attention stroke.
  readonly property bool grouped: Settings.isLoaded && Settings.data.bar.groupSections

  Chamfer {
    anchors.fill: parent
    chamferSize: root.grouped ? Tokens.chamferIcon : Tokens.chamferModule
    cutTopLeft: root.invertChamfer
    cutBottomRight: root.invertChamfer
    cutTopRight: !root.invertChamfer
    cutBottomLeft: !root.invertChamfer
    fillColor: root.grouped ? Color.alpha(Color.surfaceContainerHigh, hoverHandler.hovered ? 0.55 : 0) : Color.alpha(hoverHandler.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer, root.effectiveOpacity)
    strokeColor: root.attention ? Color.tertiary : Color.outlineVariant
    strokeWidth: root.grouped && !root.attention ? 0 : Tokens.borderModule
    // Rim only: the bar window is exactly the bar's thickness, so a
    // shadow has nowhere to fall.
    rimLight: !root.grouped
    rimOpacity: Tokens.rimOpacityCard
  }

  Item {
    id: contentItem
    anchors.fill: parent
  }

  NPressFeedback {
    id: press
    scaleTarget: root
    chamferSize: Tokens.chamferModule
    invertChamfer: root.invertChamfer
  }

  HoverHandler {
    id: hoverHandler
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: {
      press.trigger();
      root.tapped();
    }
  }
  TapHandler {
    acceptedButtons: Qt.RightButton
    onTapped: root.secondaryTapped()
  }
}
