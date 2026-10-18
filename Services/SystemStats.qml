pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// CPU/memory sampled while anything watches; temperature, disks, uptime and load only while a full view is open.
Singleton {
  id: root

  property int watchers: 0
  property int fullWatchers: 0

  property real cpuPercent: 0
  property var coresUsage: []
  property real memPercent: 0
  property real memUsedGb: 0
  property real memTotalGb: 0

  property real tempC: 0
  property var disks: [] // [{target, percent, usedGb, sizeGb}]
  readonly property real rootDiskPercent: {
    var d = disks.find(x => x.target === "/");
    return d ? d.percent : 0;
  }
  property real uptimeSeconds: 0
  readonly property string uptimeText: {
    var d = Math.floor(uptimeSeconds / 86400);
    var h = Math.floor((uptimeSeconds % 86400) / 3600);
    var m = Math.floor((uptimeSeconds % 3600) / 60);
    return (d > 0 ? d + "d " : "") + String(h).padStart(2, "0") + ":" + String(m).padStart(2, "0");
  }
  property real loadAvg1: 0
  property real loadAvg5: 0
  property real loadAvg15: 0

  property var _prevCpu: null
  property var _prevCores: []

  function refresh(): void {
    statFile.reload();
    memFile.reload();
    if (fullWatchers > 0) {
      uptimeFile.reload();
      loadFile.reload();
      if (!sensorsProc.running)
        sensorsProc.running = true;
      if (!diskProc.running)
        diskProc.running = true;
    }
  }

  // guest/guest_nice are already counted in user/nice, so only the first eight fields add up to the total.
  function _sample(line: string): var {
    var p = line.split(/\s+/).slice(1, 9).map(n => parseInt(n) || 0);
    return {
      "total": p.reduce((a, b) => a + b, 0),
      "idle": p[3] + p[4]
    };
  }

  function _usage(prev: var, cur: var): real {
    if (!prev)
      return -1;
    var dTotal = cur.total - prev.total;
    return dTotal > 0 ? Math.max(0, Math.min(100, 100 * (1 - (cur.idle - prev.idle) / dTotal))) : -1;
  }

  function _parseStat(text: string): void {
    var lines = text.split("\n").filter(l => l.startsWith("cpu"));
    if (lines.length === 0)
      return;
    var agg = _sample(lines[0]);
    var pct = _usage(_prevCpu, agg);
    if (pct >= 0)
      cpuPercent = pct;
    _prevCpu = agg;

    var cores = lines.slice(1).map(l => _sample(l));
    var usage = coresUsage.length === cores.length ? coresUsage.slice() : new Array(cores.length).fill(0);
    for (var i = 0; i < cores.length; i++) {
      var c = _usage(_prevCores[i], cores[i]);
      if (c >= 0)
        usage[i] = c;
    }
    coresUsage = usage;
    _prevCores = cores;
  }

  function _parseMem(text: string): void {
    var total = 0, avail = 0;
    for (const l of text.split("\n")) {
      if (l.startsWith("MemTotal:"))
        total = parseInt(l.split(/\s+/)[1]) || 0;
      else if (l.startsWith("MemAvailable:"))
        avail = parseInt(l.split(/\s+/)[1]) || 0;
    }
    if (total <= 0)
      return;
    memPercent = 100 * (1 - avail / total);
    memUsedGb = (total - avail) / (1024 * 1024);
    memTotalGb = total / (1024 * 1024);
  }

  // k10temp's Tctl is the AMD CPU control temperature; elsewhere the first temp1_input `sensors -j` reports.
  function _parseSensors(text: string): void {
    try {
      var data = JSON.parse(text);
      for (var chip in data) {
        if (chip.startsWith("k10temp") && data[chip].Tctl) {
          tempC = data[chip].Tctl.temp1_input;
          return;
        }
      }
      for (var chip2 in data) {
        for (var sensor in data[chip2]) {
          if (data[chip2][sensor] && data[chip2][sensor].temp1_input !== undefined) {
            tempC = data[chip2][sensor].temp1_input;
            return;
          }
        }
      }
    } catch (e) {}
  }

  readonly property Timer poll: Timer {
    interval: Settings.data.systemMonitor.refreshInterval
    running: root.watchers > 0 || root.fullWatchers > 0
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  readonly property FileView statFile: FileView {
    path: "/proc/stat"
    onLoaded: root._parseStat(text())
  }

  readonly property FileView memFile: FileView {
    path: "/proc/meminfo"
    onLoaded: root._parseMem(text())
  }

  readonly property FileView uptimeFile: FileView {
    path: "/proc/uptime"
    onLoaded: root.uptimeSeconds = parseFloat(text().split(" ")[0]) || 0
  }

  readonly property FileView loadFile: FileView {
    path: "/proc/loadavg"
    onLoaded: {
      var p = text().trim().split(/\s+/);
      root.loadAvg1 = parseFloat(p[0]) || 0;
      root.loadAvg5 = parseFloat(p[1]) || 0;
      root.loadAvg15 = parseFloat(p[2]) || 0;
    }
  }

  readonly property Process sensorsProc: Process {
    command: ["sh", "-c", "sensors -j 2>/dev/null"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root._parseSensors(text)
    }
  }

  // Real backing filesystems only; pseudo and virtual mounts are excluded.
  readonly property Process diskProc: Process {
    command: ["sh", "-c", "df --output=target,pcent,used,size -x tmpfs -x devtmpfs -x overlay -x squashfs -x proc -x sysfs -x cgroup -x cgroup2 -x tracefs -x debugfs -x securityfs -x pstore -x autofs -x mqueue -x hugetlbfs -x devpts -x rpc_pipefs -x nsfs -x efivarfs --block-size=1 2>/dev/null"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var out = [];
        var lines = text.trim().split("\n");
        for (var i = 1; i < lines.length; i++) {
          var p = lines[i].trim().split(/\s+/);
          if (p.length < 4)
            continue;
          out.push({
            "target": p[0],
            "percent": parseInt(p[1].replace(/[^0-9]/g, "")) || 0,
            "usedGb": (parseFloat(p[2]) || 0) / 1e9,
            "sizeGb": (parseFloat(p[3]) || 0) / 1e9
          });
        }
        root.disks = out;
      }
    }
  }
}
