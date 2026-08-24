import QtQuick
import Quickshell.Io
import qs.Commons

// CPU% / RAM% readout. Parsing logic (/proc/stat delta-based CPU usage,
// /proc/meminfo MemTotal-MemAvailable) ported from noctalia's
// Services/System/SystemStatService.qml.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  property real cpuPercent: 0
  property real memPercent: 0
  property var prevCpuStats: null

  implicitWidth: label.implicitWidth + 16
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  function calculateLineUsage(line) {
    var parts = line.split(/\s+/);
    return {
      "user": parseInt(parts[1]) || 0,
      "nice": parseInt(parts[2]) || 0,
      "system": parseInt(parts[3]) || 0,
      "idle": parseInt(parts[4]) || 0,
      "iowait": parseInt(parts[5]) || 0,
      "irq": parseInt(parts[6]) || 0,
      "softirq": parseInt(parts[7]) || 0,
      "steal": parseInt(parts[8]) || 0,
      "guest": parseInt(parts[9]) || 0,
      "guestNice": parseInt(parts[10]) || 0
    };
  }

  function totalOf(s) {
    var t = 0;
    for (var k in s)
      t += s[k];
    return t;
  }

  function parseCpuStat(text) {
    if (!text)
      return;
    var line = text.split("\n")[0];
    if (line.indexOf("cpu ") !== 0)
      return;
    var curr = calculateLineUsage(line);
    if (root.prevCpuStats) {
      var currIdle = curr.idle + curr.iowait;
      var prevIdle = root.prevCpuStats.idle + root.prevCpuStats.iowait;
      var diffTotal = totalOf(curr) - totalOf(root.prevCpuStats);
      var diffIdle = currIdle - prevIdle;
      if (diffTotal > 0)
        root.cpuPercent = Math.round(((diffTotal - diffIdle) / diffTotal) * 100);
    }
    root.prevCpuStats = curr;
  }

  function parseMemInfo(text) {
    if (!text)
      return;
    var lines = text.split("\n");
    var memTotal = 0, memAvailable = 0;
    for (var i = 0; i < lines.length; i++) {
      var l = lines[i];
      if (l.indexOf("MemTotal:") === 0)
        memTotal = parseInt(l.split(/\s+/)[1]) || 0;
      else if (l.indexOf("MemAvailable:") === 0)
        memAvailable = parseInt(l.split(/\s+/)[1]) || 0;
    }
    if (memTotal > 0)
      root.memPercent = Math.round(((memTotal - memAvailable) / memTotal) * 100);
  }

  FileView {
    id: cpuStatFile
    path: "/proc/stat"
    onLoaded: root.parseCpuStat(text())
  }

  FileView {
    id: memInfoFile
    path: "/proc/meminfo"
    onLoaded: root.parseMemInfo(text())
  }

  Timer {
    interval: Settings.data.systemMonitor.refreshInterval
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      cpuStatFile.reload();
      memInfoFile.reload();
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: Style.radiusXXS
    color: "transparent"

    Text {
      id: label
      anchors.centerIn: parent
      text: "CPU " + root.cpuPercent + "%  RAM " + root.memPercent + "%"
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: 11
      color: root.cpuPercent >= Settings.data.systemMonitor.warnThreshold || root.memPercent >= Settings.data.systemMonitor.warnThreshold ? Color.mError : Color.mOnSurface
    }
  }
}
