import QtQuick
import qs.Modules.Bar.Extras
import qs.Commons
import qs.Widgets

// Blue-light filter toggle. Click cycles off -> on -> forced -> off.
// wlsunset itself is owned by Commons/NightLightService.qml, so night light
// works whether or not this widget is on the bar.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  readonly property bool active: NightLightService.enabled
  readonly property bool forced: NightLightService.forced

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarIconButton {
    id: btn
    attention: root.forced
    onTapped: NightLightService.cycle()

    // Crescent-moon glyph (circle minus an offset circle) — outline when
    // off, filled primary when on, filled tertiary when forced. No
    // font/emoji glyph dependency.
    Canvas {
      id: moonCanvas
      anchors.centerIn: parent
      width: 16
      height: 16
      readonly property color drawColor: root.forced ? Color.tertiary : (root.active ? Color.primary : Color.surfaceTextMuted)
      onDrawColorChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = drawColor;
        ctx.strokeStyle = drawColor;
        ctx.lineWidth = 1.4;

        var cx = width / 2;
        var cy = height / 2;
        var r = 6;

        if (root.active) {
          ctx.beginPath();
          ctx.arc(cx, cy, r, 0, Math.PI * 2);
          ctx.fill();
          ctx.globalCompositeOperation = "destination-out";
          ctx.beginPath();
          ctx.arc(cx + 3, cy - 2, r - 1.5, 0, Math.PI * 2);
          ctx.fill();
          ctx.globalCompositeOperation = "source-over";
        } else {
          ctx.beginPath();
          ctx.arc(cx, cy, r - 1, 0, Math.PI * 2);
          ctx.stroke();
        }
      }
    }
  }
}
