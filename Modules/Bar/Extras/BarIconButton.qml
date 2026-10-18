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

  implicitWidth: Tokens.barCell
  implicitHeight: Tokens.barCell
  width: implicitWidth
  height: implicitHeight

  // In a grouped section the section draws the surface; this keeps only hover and the attention stroke.
  readonly property bool grouped: Settings.isLoaded && Settings.data.bar.groupSections

  Chamfer {
    anchors.fill: parent
    chamferSize: root.grouped ? Tokens.chamferGroupedCell : Tokens.chamferModule
    cutTopLeft: root.invertChamfer
    cutBottomRight: root.invertChamfer
    cutTopRight: !root.invertChamfer
    cutBottomLeft: !root.invertChamfer
    fillColor: root.grouped ? Colors.alpha(Colors.primary, hoverHandler.hovered ? 0.16 : 0) : Colors.alpha(hoverHandler.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer, Tokens.barModuleAlpha)
    strokeColor: root.attention ? Colors.tertiary : Colors.outlineVariant
    strokeWidth: root.grouped && !root.attention ? 0 : Tokens.borderModule
    // Rim only: the bar window is exactly the bar's thickness, so a shadow has nowhere to fall.
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
    // Same shape as the hover fill, so a press doesn't change the outline.
    chamferSize: root.grouped ? Tokens.chamferGroupedCell : Tokens.chamferModule
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
