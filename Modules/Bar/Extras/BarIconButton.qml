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

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferModule
    cutTopLeft: root.invertChamfer
    cutBottomRight: root.invertChamfer
    cutTopRight: !root.invertChamfer
    cutBottomLeft: !root.invertChamfer
    fillColor: Color.alpha(hoverHandler.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer, root.effectiveOpacity)
    strokeColor: root.attention ? Color.tertiary : Color.outlineVariant
    strokeWidth: Tokens.borderModule
  }

  Item {
    id: contentItem
    anchors.fill: parent
  }

  HoverHandler {
    id: hoverHandler
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: root.tapped()
  }
  TapHandler {
    acceptedButtons: Qt.RightButton
    onTapped: root.secondaryTapped()
  }
}
