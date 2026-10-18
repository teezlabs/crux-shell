import QtQuick
import qs.Commons

// Wi-Fi fan on a Canvas: a dot and three arcs, sized from the item so nothing clips.
Canvas {
  id: root

  property color color: Colors.surfaceText
  property real lineWidth: 1.5

  implicitWidth: 18
  implicitHeight: 14

  onColorChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()

  onPaint: {
    const ctx = getContext("2d");
    ctx.reset();
    ctx.strokeStyle = root.color;
    ctx.fillStyle = root.color;
    ctx.lineWidth = root.lineWidth;
    ctx.lineCap = "round";

    const dot = root.lineWidth;
    const cx = width / 2;
    const cy = height - dot - 0.5;
    // Largest arc that clears the top edge and, at 45 degrees either side, the side edges.
    const maxR = Math.min(cy - root.lineWidth, (width / 2 - root.lineWidth) / Math.SQRT1_2);

    for (let i = 1; i <= 3; i++) {
      ctx.beginPath();
      ctx.arc(cx, cy, maxR * i / 3, Math.PI * 1.25, Math.PI * 1.75);
      ctx.stroke();
    }

    ctx.beginPath();
    ctx.arc(cx, cy, dot, 0, Math.PI * 2);
    ctx.fill();
  }
}
