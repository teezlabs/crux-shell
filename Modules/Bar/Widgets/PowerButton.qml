import QtQuick
import qs.Modules.Bar.Extras
import qs.Commons

// Plain power icon on the bar. The honeycomb action menu lives in the
// separate PowerMenuWindow popup — the bar strip is too thin to host it.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  implicitWidth: 32
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  PowerMenuWindow {
    id: menu
    targetScreen: root.screen
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: 4
    radius: 6
    color: hoverHandler.hovered ? Color.mOutline : "transparent"

    // Geometric power-symbol glyph (circle with a top notch + vertical
    // stroke) drawn on Canvas — the previous "⏻" text glyph rendered with
    // enough font-metric baseline offset to look visibly off-center in the
    // bar despite anchors.centerIn, the same class of issue documented in
    // the crux skill's font gotchas. No font/emoji glyph dependency now.
    Canvas {
      anchors.centerIn: parent
      width: 15
      height: 15
      readonly property color drawColor: Color.mOnSurface
      onDrawColorChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = drawColor;
        ctx.lineWidth = 1.5;
        ctx.lineCap = "round";
        var cx = width / 2;
        var cy = height / 2;
        var r = width / 2 - 1;

        ctx.beginPath();
        ctx.arc(cx, cy, r, Math.PI * 0.15, Math.PI * 1.85);
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(cx, 0);
        ctx.lineTo(cx, cy - 1);
        ctx.stroke();
      }
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
