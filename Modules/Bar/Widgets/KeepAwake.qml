import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Services

// Toggles IdleInhibitorService, shared with the Control Center IDLE tile.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property bool invertChamfer: false

  readonly property bool active: IdleInhibitorService.active

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarPill {
    id: btn
    invertChamfer: root.invertChamfer
    vertical: root.vertical
    label: "Awake"
    forceOpen: root.active
    attention: root.active
    onTapped: IdleInhibitorService.toggle()

    // Open eye (awake, active) / closed eye (asleep, inactive) glyph.
    Canvas {
      anchors.centerIn: parent
      width: 18
      height: 12
      readonly property bool isActive: root.active
      readonly property color drawColor: root.active ? Colors.tertiary : Colors.surfaceText
      onIsActiveChanged: requestPaint()
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

        if (isActive) {
          // Open eye: almond outline + pupil.
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
          // Closed eye: single lash-curve line.
          ctx.beginPath();
          ctx.moveTo(1, cy);
          ctx.quadraticCurveTo(cx, cy + 5, width - 1, cy);
          ctx.stroke();
        }
      }
    }
  }
}
