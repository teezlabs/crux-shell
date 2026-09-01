import QtQuick
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel

// Gear icon on the bar; the actual settings UI lives in the separate
// SettingsWindow popup.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool invertChamfer: false

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  SettingsWindow {
    id: menu
    targetScreen: root.screen
  }

  BarIconButton {
    id: btn
    invertChamfer: root.invertChamfer
    onTapped: menu.toggle()

    // Geometric gear glyph: a ring with notches, drawn on Canvas.
    Canvas {
      anchors.centerIn: parent
      width: 16
      height: 16
      readonly property color drawColor: Color.surfaceTextMuted
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
}
