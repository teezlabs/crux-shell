import QtQuick
import qs.Commons
import qs.Modules.ControlCenter

// Silences notification toasts; history still records them.
CcCircleToggle {
  id: tile

  active: Settings.data.notifications.doNotDisturb
  onTapped: Settings.data.notifications.doNotDisturb = !Settings.data.notifications.doNotDisturb

  // Drawn bell (the icon theme has none), struck through while silenced.
  Canvas {
    anchors.centerIn: parent
    width: 14
    height: 15
    readonly property color strokeColor: tile.active ? Colors.primaryText : Colors.surfaceText
    readonly property bool struck: tile.active
    onStrokeColorChanged: requestPaint()
    onStruckChanged: requestPaint()
    onPaint: {
      var ctx = getContext("2d");
      ctx.reset();
      ctx.strokeStyle = strokeColor;
      ctx.lineWidth = 1.3;
      ctx.lineJoin = "round";
      ctx.beginPath();
      ctx.moveTo(1.5, 10);
      ctx.lineTo(1.5, 7);
      ctx.bezierCurveTo(1.5, 3.5, 4, 2, 7, 2);
      ctx.bezierCurveTo(10, 2, 12.5, 3.5, 12.5, 7);
      ctx.lineTo(12.5, 10);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(1, 10);
      ctx.lineTo(13, 10);
      ctx.stroke();
      ctx.beginPath();
      ctx.arc(7, 12.4, 1.4, 0, Math.PI * 2);
      ctx.stroke();
      if (struck) {
        ctx.beginPath();
        ctx.moveTo(1.5, 14);
        ctx.lineTo(12.5, 1);
        ctx.stroke();
      }
    }
  }
}
