import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras

// Compact session-usage readout on the bar; full detail (session + weekly,
// reset times, today's tokens) lives in the claudeUsage popup hosted by
// PopupHost.qml.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  readonly property string _binDir: Quickshell.env("HOME") + "/.config/quickshell/crux/bin/"
  property var record: ({})
  readonly property var limits: record.limits || []
  readonly property var sessionLimit: {
    for (var i = 0; i < limits.length; i++) {
      if (limits[i] && limits[i].label === "Session (5-hour)")
        return limits[i];
    }
    return null;
  }
  readonly property real sessionPercent: sessionLimit ? sessionLimit.percent : -1
  readonly property var weeklyLimit: {
    for (var i = 0; i < limits.length; i++) {
      if (limits[i] && limits[i].label === "Weekly (7-day)")
        return limits[i];
    }
    return null;
  }
  readonly property real weeklyPercent: weeklyLimit ? weeklyLimit.percent : -1

  Process {
    id: fetchProc
    command: [root._binDir + "crux-agent-usage-claude", "--limits-only"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          root.record = JSON.parse(text);
        } catch (e) {}
      }
    }
  }

  Timer {
    interval: 60000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: if (!fetchProc.running)
      fetchProc.running = true
  }

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarIconButton {
    id: btn
    attention: root.sessionPercent > 0.85
    onTapped: {
      var pos = root.mapToItem(null, 0, 0);
      Popups.openAt("claudeUsage", root.screen, pos.x, pos.y);
    }

    // Geometric robot glyph: rounded head outline + two eye dots + antenna —
    // no font/emoji glyph dependency (the bundled Tabler font was fine, but
    // moving off it keeps this widget consistent with the rest of the v2
    // bar's "no icon font" rule).
    Canvas {
      anchors.centerIn: parent
      width: 14
      height: 14
      readonly property color drawColor: root.sessionPercent > 0.85 ? Color.error : Color.surfaceText
      onDrawColorChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = drawColor;
        ctx.fillStyle = drawColor;
        ctx.lineWidth = 1.3;

        ctx.beginPath();
        ctx.moveTo(7, 0.5);
        ctx.lineTo(7, 2.5);
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(7, 0.5, 0.9, 0, Math.PI * 2);
        ctx.fill();

        ctx.strokeRect(1, 2.5, 12, 10);

        ctx.beginPath();
        ctx.arc(4.5, 7, 1, 0, Math.PI * 2);
        ctx.fill();
        ctx.beginPath();
        ctx.arc(9.5, 7, 1, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }
}
