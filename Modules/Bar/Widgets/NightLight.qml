import QtQuick
import qs.Commons
import qs.Widgets
import qs.Modules.Bar.Extras
import qs.Services

// Click cycles off -> on -> forced. NightLightService owns wlsunset, so this widget is optional.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property bool invertChamfer: false

  readonly property bool active: NightLightService.enabled
  readonly property bool forced: NightLightService.forced

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarPill {
    id: btn
    invertChamfer: root.invertChamfer
    vertical: root.vertical
    label: root.forced ? "Forced" : "Night"
    forceOpen: root.forced
    attention: root.forced
    onTapped: NightLightService.cycle()

    // Crescent: outline when off, primary fill when on, tertiary when forced.
    Canvas {
      id: moonCanvas
      anchors.centerIn: parent
      width: 16
      height: 16
      readonly property color drawColor: root.forced ? Colors.tertiary : (root.active ? Colors.primary : Colors.surfaceTextMuted)
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
