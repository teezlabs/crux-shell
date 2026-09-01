import QtQuick
import qs.Commons

// Shared chrome for every single-icon bar module (Launcher, ControlCenter,
// Wifi, Bluetooth, Sound, ClaudeUsage, Clipboard, Wallpaper, Settings):
// chamfered 32px cell (§4 chamferModule, cutTopRight+cutBottomLeft — same
// two-opposite-corner convention as every other chamfered element in
// crux), hover-lit fill, tertiary border when `attention` is set. Content
// (a Canvas/Text glyph) is the default property so each widget file stays
// just its glyph-drawing + tap handling.
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
