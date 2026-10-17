import QtQuick
import qs.Commons
import qs.Modules.SessionMenu
import qs.Widgets
import qs.Modules.Bar.Extras

// v2 spec §6.1 Power module: "32px cell, error border, ⏻." Distinct from
// the generic BarModule treatment (error border instead of outlineVariant,
// fixed 32px square instead of content-sized) since it's the one
// permanently-destructive action living in the bar.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool invertChamfer: false

  implicitWidth: 32
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  PowerMenuWindow {
    id: menu
    targetScreen: root.screen
  }

  // Inside a grouped section the surface belongs to the section, but the
  // destructive stroke stays — it is the one accent the bar keeps.
  readonly property bool grouped: Settings.isLoaded && Settings.data.bar.groupSections

  Chamfer {
    anchors.fill: parent
    chamferSize: root.grouped ? Tokens.chamferGroupedCell : Tokens.chamferModule
    cutTopLeft: root.invertChamfer
    cutBottomRight: root.invertChamfer
    cutTopRight: !root.invertChamfer
    cutBottomLeft: !root.invertChamfer
    fillColor: root.grouped ? Colors.alpha(Colors.primary, hoverHandler.hovered ? 0.16 : 0) : Colors.alpha(hoverHandler.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer, Tokens.barModuleOpacity)
    strokeColor: Colors.alpha(Colors.error, Tokens.destructiveBorderAlpha)
    strokeWidth: Tokens.borderModule
  }

  // Geometric ⏻ glyph (circle + top tick), not a font glyph — the real
  // Unicode "⏻" character centers unevenly depending on the active font's
  // own ink metrics for that symbol (confirmed visually off-center after
  // a font change). Same shape the crux-themed SDDM greeter draws.
  Canvas {
    id: glyphCanvas
    anchors.centerIn: parent
    width: 14
    height: 14
    readonly property color drawColor: Colors.error
    onDrawColorChanged: requestPaint()
    onPaint: {
      var ctx = getContext("2d");
      ctx.reset();
      ctx.strokeStyle = drawColor;
      ctx.lineWidth = 1.4;
      ctx.lineCap = "round";
      var cx = width / 2, cy = height / 2;
      // Canvas angle 0 is 3 o'clock, not 12 — the gap needs to be centered
      // on -PI/2 (top) to line up with the vertical tick below, not on PI
      // (left), which is what a plain 1.2PI-2.8PI sweep actually gives.
      var top = -Math.PI / 2;
      var gap = 0.7;
      ctx.beginPath();
      ctx.arc(cx, cy + 1, 5, top + gap / 2, top - gap / 2 + Math.PI * 2);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(cx, 0);
      ctx.lineTo(cx, 6);
      ctx.stroke();
    }
  }

  HoverHandler {
    id: hoverHandler
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: menu.toggle()
  }
}
