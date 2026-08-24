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
    color: hoverHandler.hovered ? Color.alpha(Color.mPrimary, 0.16) : "transparent"
    border.color: Color.alpha(Color.mPrimary, 0.55)
    border.width: hoverHandler.hovered ? 1 : 0
    scale: hoverHandler.hovered ? 1.1 : 1.0
    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }
    Behavior on scale {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutBack
      }
    }

    // Geometric power-symbol glyph (circle with a top notch + vertical
    // stroke) drawn on Canvas — the previous "⏻" text glyph rendered with
    // enough font-metric baseline offset to look visibly off-center in the
    // bar despite anchors.centerIn, the same class of issue documented in
    // the crux skill's font gotchas. No font/emoji glyph dependency now.
    Canvas {
      anchors.centerIn: parent
      width: 16
      height: 16
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
        var r = width / 2 - 1.5;

        // Canvas arc angles are measured from the 3-o'clock point,
        // increasing clockwise, so "top" is 1.5*PI, not 0 - the previous
        // version's gap (centered on angle 0, i.e. 3 o'clock) didn't line
        // up with the vertical stroke below at all, which is what actually
        // looked wrong, not just "off-center".
        var gapHalf = 0.16;
        ctx.beginPath();
        ctx.arc(cx, cy, r, (1.5 + gapHalf) * Math.PI, (1.5 - gapHalf) * Math.PI + 2 * Math.PI);
        ctx.stroke();

        ctx.beginPath();
        ctx.moveTo(cx, cy - r - 1);
        ctx.lineTo(cx, cy - r * 0.15);
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
