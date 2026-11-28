import QtQuick
import qs.Commons
import qs.Services

// FFT bands from SpectrumService drawn like the weather curve: a smooth line over a fading fill. Holds cava only while `running`.
Item {
  id: root

  property bool running: false
  // Square markers on each band, as on the weather curve; off where they'd crowd.
  property bool markers: true

  implicitHeight: 28

  onRunningChanged: running ? SpectrumService.acquire() : SpectrumService.release()
  Component.onCompleted: if (running)
    SpectrumService.acquire()
  Component.onDestruction: if (running)
    SpectrumService.release()

  Canvas {
    id: curve
    anchors.fill: parent

    // Canvas colours aren't bindings, so repaint on a theme change.
    readonly property color lineColor: Colors.primary
    readonly property var values: SpectrumService.values

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onValuesChanged: requestPaint()

    onPaint: {
      const ctx = getContext("2d");
      ctx.reset();
      // Neighbouring bands averaged in pairs, so the markers sit about as far apart as the weather curve's.
      const raw = curve.values || [];
      const v = [];
      for (let i = 0; i + 1 < raw.length; i += 2)
        v.push((raw[i] + raw[i + 1]) / 2);
      if (v.length < 2)
        v.splice(0, v.length, 0, 0);
      // Room above for the line and markers at full level.
      const top = 3;
      const bottom = height - 1;
      const step = width / v.length;
      const pts = v.map((level, i) => [step * (i + 0.5), bottom - (bottom - top) * Math.max(0, Math.min(1, level))]);

      const path = () => {
        ctx.moveTo(0, pts[0][1]);
        ctx.lineTo(pts[0][0], pts[0][1]);
        for (let i = 1; i < pts.length; i++) {
          const mx = (pts[i - 1][0] + pts[i][0]) / 2;
          ctx.bezierCurveTo(mx, pts[i - 1][1], mx, pts[i][1], pts[i][0], pts[i][1]);
        }
        ctx.lineTo(width, pts[pts.length - 1][1]);
      };

      ctx.beginPath();
      path();
      ctx.lineTo(width, bottom);
      ctx.lineTo(0, bottom);
      ctx.closePath();
      const grad = ctx.createLinearGradient(0, top, 0, bottom);
      grad.addColorStop(0, Colors.alpha(lineColor, 0.35));
      grad.addColorStop(1, Colors.alpha(lineColor, 0));
      ctx.fillStyle = grad;
      ctx.fill();

      ctx.beginPath();
      path();
      ctx.strokeStyle = lineColor;
      ctx.lineWidth = 1.6;
      ctx.stroke();

      if (!root.markers)
        return;
      // Square markers: crux has no round shapes.
      ctx.fillStyle = lineColor;
      for (const p of pts)
        ctx.fillRect(p[0] - 1.5, p[1] - 1.5, 3, 3);
    }
  }
}
