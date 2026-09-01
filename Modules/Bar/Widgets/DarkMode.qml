import QtQuick
import qs.Commons
import qs.Modules.Bar.Extras

// Light/dark toggle. Crux's theme is matugen-driven, not a fixed palette — click just re-maps Settings.data.theme via Matugen.setDarkMode().
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  readonly property bool dark: Settings.data.theme.darkMode

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarIconButton {
    id: btn
    onTapped: Matugen.setDarkMode(!root.dark)

    // Sun (light) / moon (dark) glyph, geometric — no font/emoji dependency.
    Canvas {
      id: canvas
      anchors.centerIn: parent
      width: 16
      height: 16
      readonly property bool isDark: root.dark
      readonly property color drawColor: Color.surfaceText
      onIsDarkChanged: requestPaint()
      onDrawColorChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = drawColor;
        ctx.fillStyle = drawColor;
        ctx.lineWidth = 1.3;
        ctx.lineCap = "round";
        var cx = width / 2;
        var cy = height / 2;

        if (isDark) {
          // Crescent moon: full circle minus an offset circle, via an
          // even-odd fill rule (no compositing needed on a transparent
          // canvas backdrop).
          ctx.beginPath();
          ctx.arc(cx, cy, 6, 0, Math.PI * 2);
          ctx.arc(cx + 3.2, cy - 2, 6, 0, Math.PI * 2, true);
          ctx.fill("evenodd");
        } else {
          ctx.beginPath();
          ctx.arc(cx, cy, 3.4, 0, Math.PI * 2);
          ctx.fill();
          for (var i = 0; i < 8; i++) {
            var a = (Math.PI / 4) * i;
            var r1 = 5.2;
            var r2 = 7.2;
            ctx.beginPath();
            ctx.moveTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1);
            ctx.lineTo(cx + Math.cos(a) * r2, cy + Math.sin(a) * r2);
            ctx.stroke();
          }
        }
      }
    }
  }
}
