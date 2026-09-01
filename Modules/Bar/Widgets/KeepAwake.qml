import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras

// Inhibits idle/sleep via its own systemd-inhibit subprocess (no shared idle-inhibitor singleton yet).
// If multiple KeepAwake widgets are added, each manages its own inhibitor independently.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  property bool active: false

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  Process {
    id: inhibitorProcess
    running: false
    command: ["systemd-inhibit", "--what=idle:sleep", "--why=Manually activated by user", "--mode=block", "sleep", "infinity"]
    onExited: function (exitCode, exitStatus) {
      if (root.active) {
        root.active = false;
      }
    }
  }

  function toggle() {
    if (root.active) {
      inhibitorProcess.running = false;
      root.active = false;
    } else {
      inhibitorProcess.running = true;
      root.active = true;
    }
  }

  Component.onDestruction: {
    if (inhibitorProcess.running)
      inhibitorProcess.running = false;
  }

  BarIconButton {
    id: btn
    attention: root.active
    onTapped: root.toggle()

    // Open eye (awake, active) / closed eye (asleep, inactive) glyph.
    Canvas {
      anchors.centerIn: parent
      width: 18
      height: 12
      readonly property bool isActive: root.active
      readonly property color drawColor: root.active ? Color.tertiary : Color.surfaceText
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
