import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras

// CPU%/RAM% readout (delta-based /proc/stat, MemTotal-MemAvailable). Click opens SystemStatsWindow for full telemetry.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false

  SystemStatsWindow {
    id: statsWindow
    targetScreen: root.screen
  }

  property real cpuPercent: 0
  property real memPercent: 0
  property var prevCpuStats: null
  readonly property bool warn: cpuPercent >= Settings.data.systemMonitor.warnThreshold || memPercent >= Settings.data.systemMonitor.warnThreshold

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

  implicitWidth: module.implicitWidth
  implicitHeight: module.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarModule {
    id: module
    vertical: root.vertical
    topPadding: 8
    bottomPadding: 8

    Row {
      visible: !root.vertical
      spacing: 10

      StatText {
        label: "CPU"
        value: root.cpuPercent + "%"
        valueColor: root.warn ? Color.error : Color.surfaceText
      }

      Rectangle {
        width: 1
        height: 12
        color: Color.surfaceContainerHigh
      }

      StatText {
        label: "RAM"
        value: root.memPercent + "%"
        valueColor: root.warn ? Color.error : Color.surfaceText
      }
    }

    Column {
      visible: root.vertical
      spacing: 8

      Column {
        width: 28
        Text {
          width: 28
          horizontalAlignment: Text.AlignHCenter
          text: root.cpuPercent + "%"
          color: root.warn ? Color.error : Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
        Text {
          width: 28
          horizontalAlignment: Text.AlignHCenter
          text: "CPU"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize - 1
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
      }

      Rectangle {
        width: 28
        height: 1
        color: Color.surfaceContainerHigh
      }

      Column {
        width: 28
        Text {
          width: 28
          horizontalAlignment: Text.AlignHCenter
          text: root.memPercent + "%"
          color: root.warn ? Color.error : Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
        Text {
          width: 28
          horizontalAlignment: Text.AlignHCenter
          text: "RAM"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize - 1
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
      }
    }
  }

  HoverHandler {
    cursorShape: Qt.PointingHandCursor
    onHoveredChanged: {
      if (hovered)
        TooltipService.show(root, "CPU " + root.cpuPercent + "%  ·  RAM " + root.memPercent + "%");
      else
        TooltipService.hide();
    }
  }
  TapHandler {
    onTapped: {
      TooltipService.hideImmediately();
      statsWindow.triggerPos = root.mapToItem(null, 0, 0);
      statsWindow.toggle();
    }
  }
  onCpuPercentChanged: if (TooltipService.anchorItem === root)
    TooltipService.text = "CPU " + root.cpuPercent + "%  ·  RAM " + root.memPercent + "%"
  onMemPercentChanged: if (TooltipService.anchorItem === root)
    TooltipService.text = "CPU " + root.cpuPercent + "%  ·  RAM " + root.memPercent + "%"
}
