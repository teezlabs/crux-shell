import QtQuick
import qs.Commons
import qs.Modules.SessionMenu
import qs.Widgets
import qs.Modules.Bar.Extras

// Power module (spec §6.1): a square cell with the error border, the bar's one destructive action.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool invertChamfer: false

  implicitWidth: Tokens.barCell
  implicitHeight: Tokens.barCell
  width: implicitWidth
  height: implicitHeight

  PowerMenuWindow {
    id: menu
    targetScreen: root.screen
  }

  // In a grouped section the surface belongs to the section, but the destructive stroke stays.
  readonly property bool grouped: Settings.isLoaded && Settings.data.bar.groupSections

  Chamfer {
    anchors.fill: parent
    chamferSize: root.grouped ? Tokens.chamferGroupedCell : Tokens.chamferModule
    cutTopLeft: root.invertChamfer
    cutBottomRight: root.invertChamfer
    cutTopRight: !root.invertChamfer
    cutBottomLeft: !root.invertChamfer
    fillColor: root.grouped ? Colors.alpha(Colors.primary, hoverHandler.hovered ? 0.16 : 0) : Colors.alpha(hoverHandler.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer, Tokens.barModuleAlpha)
    strokeColor: Colors.alpha(Colors.error, Tokens.destructiveBorderAlpha)
    strokeWidth: Tokens.borderModule
  }

  // Drawn rather than the Unicode glyph, which centres unevenly depending on the font. Matches the SDDM greeter.
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
      // Canvas angle 0 is 3 o'clock, so the gap centres on -PI/2 to sit over the tick.
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
