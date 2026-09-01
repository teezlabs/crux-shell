import QtQuick
import qs.Commons

// Geometric weather glyph drawn on Canvas — same "no icon font" rule every
// other icon in crux follows (see the crux skill's font gotchas). Six
// categories, matching Weather.qml's iconCategory(): sun, partly (sun +
// cloud), cloud, fog, rain, snow, storm.
Canvas {
  id: root

  property string category: "cloud"
  property color strokeColor: Color.surfaceText
  property color accentColor: Color.tertiary

  onCategoryChanged: requestPaint()
  onStrokeColorChanged: requestPaint()
  onAccentColorChanged: requestPaint()

  function drawSun(ctx, cx, cy, r) {
    ctx.strokeStyle = root.accentColor;
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.stroke();
    for (var i = 0; i < 8; i++) {
      var a = (Math.PI * 2 * i) / 8;
      var x1 = cx + Math.cos(a) * (r + 2);
      var y1 = cy + Math.sin(a) * (r + 2);
      var x2 = cx + Math.cos(a) * (r + 5);
      var y2 = cy + Math.sin(a) * (r + 5);
      ctx.beginPath();
      ctx.moveTo(x1, y1);
      ctx.lineTo(x2, y2);
      ctx.stroke();
    }
  }

  // Filled overlapping circles, not a stroked multi-arc path — chained arcs self-intersected into a tangled scribble at small sizes.
  function drawCloud(ctx, cx, cy, scale) {
    ctx.fillStyle = root.strokeColor;
    ctx.beginPath();
    ctx.arc(cx - 5 * scale, cy + 2 * scale, 4 * scale, 0, Math.PI * 2);
    ctx.arc(cx - 1 * scale, cy - 2 * scale, 5 * scale, 0, Math.PI * 2);
    ctx.arc(cx + 5 * scale, cy + 1 * scale, 4.5 * scale, 0, Math.PI * 2);
    ctx.arc(cx, cy + 4 * scale, 4.5 * scale, 0, Math.PI * 2);
    ctx.fill();
  }

  function drawDrops(ctx, cx, cy, color) {
    ctx.strokeStyle = color;
    ctx.lineWidth = 1.4;
    ctx.lineCap = "round";
    for (var i = 0; i < 3; i++) {
      var x = cx - 5 + i * 5;
      ctx.beginPath();
      ctx.moveTo(x, cy + 7);
      ctx.lineTo(x - 1, cy + 11);
      ctx.stroke();
    }
  }

  function drawFlakes(ctx, cx, cy, color) {
    ctx.strokeStyle = color;
    ctx.lineWidth = 1.2;
    for (var i = 0; i < 3; i++) {
      var x = cx - 5 + i * 5;
      var y = cy + 9;
      ctx.beginPath();
      ctx.moveTo(x - 1.5, y - 1.5);
      ctx.lineTo(x + 1.5, y + 1.5);
      ctx.moveTo(x + 1.5, y - 1.5);
      ctx.lineTo(x - 1.5, y + 1.5);
      ctx.moveTo(x - 2, y);
      ctx.lineTo(x + 2, y);
      ctx.stroke();
    }
  }

  function drawBolt(ctx, cx, cy, color) {
    ctx.strokeStyle = color;
    ctx.lineWidth = 1.4;
    ctx.lineJoin = "round";
    ctx.beginPath();
    ctx.moveTo(cx + 1, cy + 5);
    ctx.lineTo(cx - 2, cy + 11);
    ctx.lineTo(cx + 1, cy + 11);
    ctx.lineTo(cx - 2, cy + 17);
    ctx.stroke();
  }

  onPaint: {
    var ctx = getContext("2d");
    ctx.reset();
    var cx = width / 2;
    var cy = height / 2;

    if (category === "sun") {
      drawSun(ctx, cx, cy, 6);
    } else if (category === "partly") {
      drawSun(ctx, cx - 4, cy - 3, 4);
      drawCloud(ctx, cx + 2, cy + 3, 0.9);
    } else if (category === "fog") {
      drawCloud(ctx, cx, cy - 3, 0.85);
      ctx.strokeStyle = root.strokeColor;
      ctx.lineWidth = 1.2;
      for (var i = 0; i < 3; i++) {
        ctx.beginPath();
        ctx.moveTo(cx - 7, cy + 6 + i * 3);
        ctx.lineTo(cx + 7, cy + 6 + i * 3);
        ctx.stroke();
      }
    } else if (category === "rain") {
      drawCloud(ctx, cx, cy - 4, 0.85);
      drawDrops(ctx, cx, cy - 4, root.accentColor);
    } else if (category === "snow") {
      drawCloud(ctx, cx, cy - 4, 0.85);
      drawFlakes(ctx, cx, cy - 4, root.strokeColor);
    } else if (category === "storm") {
      drawCloud(ctx, cx, cy - 5, 0.85);
      drawBolt(ctx, cx, cy - 5, root.accentColor);
    } else {
      drawCloud(ctx, cx, cy, 0.95);
    }
  }
}
