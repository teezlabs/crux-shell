import QtQuick
import qs.Commons
import qs.Modules.SettingsPanel

// Plain gear icon on the bar; the actual settings UI lives in the
// separate SettingsWindow popup.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  implicitWidth: 32
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  SettingsWindow {
    id: menu
    targetScreen: root.screen
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: 4
    radius: Style.radiusXXS
    color: hoverHandler.hovered ? Color.mOutline : "transparent"

    // Geometric gear glyph: a ring with notches, drawn on Canvas — no
    // font/emoji glyph dependency.
    Canvas {
      anchors.centerIn: parent
      width: 16
      height: 16
      readonly property color drawColor: Color.mOnSurfaceVariant
      onDrawColorChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        var cx = width / 2;
        var cy = height / 2;
        var outer = 7;
        var inner = 4.5;
        var teeth = 8;

        ctx.fillStyle = drawColor;
        ctx.beginPath();
        for (var i = 0; i < teeth * 2; i++) {
          var angle = (Math.PI * 2 * i) / (teeth * 2);
          var r = i % 2 === 0 ? outer : outer - 2;
          var x = cx + r * Math.cos(angle);
          var y = cy + r * Math.sin(angle);
          if (i === 0)
            ctx.moveTo(x, y);
          else
            ctx.lineTo(x, y);
        }
        ctx.closePath();
        ctx.fill();

        ctx.globalCompositeOperation = "destination-out";
        ctx.beginPath();
        ctx.arc(cx, cy, inner - 2.5, 0, Math.PI * 2);
        ctx.fill();
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
