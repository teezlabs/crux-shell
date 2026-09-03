import QtQuick
import qs.Commons
import qs.Modules.Bar.Extras

// Keep-awake quick toggle, sharing state with the bar widget of the same
// name via Commons/IdleInhibitorService.qml.
//
// Open/closed eye drawn on Canvas rather than an icon-theme name, matching
// the bar widget and avoiding a theme that may not carry a caffeine icon.
CcCircleToggle {
  id: tile
  signal expandRequested(string which)

  active: IdleInhibitorService.active
  onTapped: IdleInhibitorService.toggle()

  Canvas {
    anchors.centerIn: parent
    width: 18
    height: 12
    readonly property bool isOn: tile.active
    readonly property color drawColor: tile.active ? Color.primaryText : Color.surfaceText
    onIsOnChanged: requestPaint()
    onDrawColorChanged: requestPaint()
    onPaint: {
      const ctx = getContext("2d");
      ctx.reset();
      ctx.strokeStyle = drawColor;
      ctx.fillStyle = drawColor;
      ctx.lineWidth = 1.3;
      ctx.lineCap = "round";
      const cx = width / 2;
      const cy = height / 2;
      if (isOn) {
        ctx.beginPath();
        ctx.moveTo(1, cy);
        ctx.quadraticCurveTo(cx, 0, width - 1, cy);
        ctx.quadraticCurveTo(cx, height, 1, cy);
        ctx.closePath();
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(cx, cy, 2.2, 0, Math.PI * 2);
        ctx.fill();
      } else {
        ctx.beginPath();
        ctx.moveTo(1, cy);
        ctx.quadraticCurveTo(cx, cy + 5, width - 1, cy);
        ctx.stroke();
      }
    }
  }
}
