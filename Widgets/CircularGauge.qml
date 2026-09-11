import QtQuick
import qs.Commons
import qs.Widgets

// Circular arc gauge for Control Center telemetry — explicitly requested
// to match a specific reference look (rounded dial meters), a deliberate
// one-off departure from the rest of the app's "no radius, chamfer
// instead" rule, scoped to this one panel only.
Item {
  id: root

  property real percent: 0 // 0..100
  property color trackColor: Color.surfaceContainerHigh
  property color fillColor: Color.primary
  property string value: ""
  property string label: ""

  implicitWidth: 52
  implicitHeight: 52

  Canvas {
    id: canvas
    anchors.fill: parent
    readonly property real pct: root.percent
    readonly property color track: root.trackColor
    readonly property color fill: root.fillColor
    onPctChanged: requestPaint()
    onTrackChanged: requestPaint()
    onFillChanged: requestPaint()
    onPaint: {
      var ctx = getContext("2d");
      ctx.reset();
      var cx = width / 2;
      var cy = height / 2;
      var r = Math.min(width, height) / 2 - 4;
      var start = Math.PI * 0.75;
      var span = Math.PI * 1.5;

      ctx.lineCap = "round";
      ctx.lineWidth = 4;
      ctx.strokeStyle = track;
      ctx.beginPath();
      ctx.arc(cx, cy, r, start, start + span);
      ctx.stroke();

      var frac = Math.max(0, Math.min(1, pct / 100));
      if (frac > 0) {
        ctx.strokeStyle = fill;
        ctx.beginPath();
        ctx.arc(cx, cy, r, start, start + span * frac);
        ctx.stroke();
      }
    }
  }

  Column {
    anchors.centerIn: parent
    spacing: 0

    NText {
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.value
      color: Color.surfaceText
      size: NText.Size.Caption
      font.weight: Font.DemiBold
    }
    NText {
      tracking: true
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.label
      color: Color.labelText
      font.pixelSize: Tokens.labelXsSize - 1
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
    }
  }
}
