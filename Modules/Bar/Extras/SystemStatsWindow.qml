import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Modules.Bar.Extras

// Full system-telemetry panel, fuller than the bar's CPU%/RAM% readout. Metric collection ported 1:1 from ControlCenterWindow.qml,
// plus per-core CPU breakdown, every mounted filesystem, and load average.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property string _barPos: Settings.isLoaded ? Settings.getBarPositionForScreen(root.targetScreen ? root.targetScreen.name : "") : "top"
  readonly property bool _barLeft: root._barPos === "left"
  readonly property bool _barRight: root._barPos === "right"
  readonly property bool _barBottom: root._barPos === "bottom"
  readonly property real _barOffset: Settings.data.bar.thickness + Settings.data.bar.floatMargin * 2 + 20

  // Bar-icon trigger position, mapped into this popup's space; -1 = not set (IPC open). See SoundMenuWindow.qml.
  property point triggerPos: Qt.point(-1, -1)
  readonly property bool _hasTrigger: triggerPos.x >= 0
  readonly property real _triggerX: triggerPos.x + Settings.data.bar.floatMargin
  readonly property real _triggerY: triggerPos.y + Settings.data.bar.floatMargin

  // ---- CPU: aggregate + per-core, delta-based from /proc/stat ----
  property real cpuPercent: 0
  property var coresUsage: []
  property var _prevCpuStats: null
  property var _prevCoreStats: []

  function _calcUsage(line) {
    var p = line.split(/\s+/);
    var s = {
      "user": parseInt(p[1]) || 0,
      "nice": parseInt(p[2]) || 0,
      "system": parseInt(p[3]) || 0,
      "idle": parseInt(p[4]) || 0,
      "iowait": parseInt(p[5]) || 0,
      "irq": parseInt(p[6]) || 0,
      "softirq": parseInt(p[7]) || 0,
      "steal": parseInt(p[8]) || 0
    };
    var total = 0;
    for (var k in s)
      total += s[k];
    return {
      "total": total,
      "idle": s.idle + s.iowait
    };
  }

  function _usagePercent(prev, cur) {
    if (!prev)
      return -1;
    var dTotal = cur.total - prev.total;
    var dIdle = cur.idle - prev.idle;
    return dTotal > 0 ? Math.max(0, Math.min(100, 100 * (1 - dIdle / dTotal))) : -1;
  }

  // ---- Memory ----
  property real memPercent: 0
  property real memUsedGb: 0
  property real memTotalGb: 0

  // ---- Temperature (k10temp Tctl, falls back to first temp1_input) ----
  property real tempC: 0

  // ---- Disk: every real mounted filesystem, not just "/" ----
  property var disks: [] // [{target, percent, usedGb, sizeGb}]

  // ---- Uptime + load average ----
  property string uptimeText: "…"
  property real loadAvg1: 0
  property real loadAvg5: 0
  property real loadAvg15: 0

  function refreshStats() {
    cpuMemProc.running = true;
    sensorsProc.running = true;
    diskProc.running = true;
    uptimeProc.running = true;
  }

  Timer {
    interval: 2000
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refreshStats()
  }

  // All "cpu"/"cpuN" lines from /proc/stat plus MemTotal/MemAvailable.
  Process {
    id: cpuMemProc
    command: ["sh", "-c", "grep '^cpu' /proc/stat; echo '---MEM---'; grep -E 'MemTotal|MemAvailable' /proc/meminfo"]
    stdout: StdioCollector {
      id: cpuMemCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      var parts = cpuMemCollector.text.split("---MEM---");
      var cpuLines = (parts[0] || "").trim().split("\n").filter(l => l.length > 0);
      var memLines = (parts[1] || "").trim().split("\n");

      if (cpuLines.length > 0) {
        // First line is the aggregate "cpu " line.
        var curAgg = root._calcUsage(cpuLines[0]);
        var aggPct = root._usagePercent(root._prevCpuStats, curAgg);
        if (aggPct >= 0)
          root.cpuPercent = aggPct;
        root._prevCpuStats = curAgg;

        // Remaining lines are per-core "cpu0", "cpu1", ...
        var coreLines = cpuLines.slice(1);
        var newCoreStats = [];
        var newCoresUsage = root.coresUsage.slice();
        if (newCoresUsage.length !== coreLines.length)
          newCoresUsage = new Array(coreLines.length).fill(0);
        for (var i = 0; i < coreLines.length; i++) {
          var cur = root._calcUsage(coreLines[i]);
          var pct = root._usagePercent(root._prevCoreStats[i], cur);
          if (pct >= 0)
            newCoresUsage[i] = pct;
          newCoreStats.push(cur);
        }
        root.coresUsage = newCoresUsage;
        root._prevCoreStats = newCoreStats;
      }

      var memTotal = 0, memAvail = 0;
      for (var j = 0; j < memLines.length; j++) {
        var m = memLines[j].match(/(\d+)/);
        if (!m)
          continue;
        if (memLines[j].indexOf("MemTotal") === 0)
          memTotal = parseInt(m[1]);
        else if (memLines[j].indexOf("MemAvailable") === 0)
          memAvail = parseInt(m[1]);
      }
      if (memTotal > 0) {
        root.memPercent = Math.max(0, Math.min(100, 100 * (1 - memAvail / memTotal)));
        root.memUsedGb = (memTotal - memAvail) / (1024 * 1024);
        root.memTotalGb = memTotal / (1024 * 1024);
      }
    }
  }

  // k10temp's Tctl is the standard AMD CPU control-temp sensor; falls back
  // to the first temp1_input `sensors -j` reports on non-AMD boxes — exact
  // same probe ControlCenterWindow.qml uses.
  Process {
    id: sensorsProc
    command: ["sh", "-c", "sensors -j 2>/dev/null"]
    stdout: StdioCollector {
      id: sensorsCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      try {
        var data = JSON.parse(sensorsCollector.text);
        var t = null;
        for (var chip in data) {
          if (chip.indexOf("k10temp") === 0 && data[chip].Tctl) {
            t = data[chip].Tctl.temp1_input;
            break;
          }
        }
        if (t === null) {
          for (var chip2 in data) {
            for (var sensor in data[chip2]) {
              if (data[chip2][sensor] && data[chip2][sensor].temp1_input !== undefined) {
                t = data[chip2][sensor].temp1_input;
                break;
              }
            }
            if (t !== null)
              break;
          }
        }
        if (t !== null)
          root.tempC = t;
      } catch (e) {}
    }
  }

  // Every real mounted filesystem, excluding tmpfs/overlay/pseudo mounts —
  // same idea as noctalia's SystemStatService df call ("-x efivarfs"),
  // extended to skip the usual noise so only genuine backing filesystems
  // show up.
  Process {
    id: diskProc
    command: ["sh", "-c", "df --output=target,pcent,used,size -x tmpfs -x devtmpfs -x overlay -x squashfs -x proc -x sysfs -x cgroup -x cgroup2 -x tracefs -x debugfs -x securityfs -x pstore -x autofs -x mqueue -x hugetlbfs -x devpts -x rpc_pipefs -x nsfs -x efivarfs --block-size=1 2>/dev/null"]
    stdout: StdioCollector {
      id: diskCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      var lines = diskCollector.text.trim().split("\n");
      var out = [];
      for (var i = 1; i < lines.length; i++) {
        var parts = lines[i].trim().split(/\s+/);
        if (parts.length < 4)
          continue;
        var target = parts[0];
        var percent = parseInt(parts[1].replace(/[^0-9]/g, "")) || 0;
        var usedBytes = parseFloat(parts[2]) || 0;
        var sizeBytes = parseFloat(parts[3]) || 0;
        out.push({
                    "target": target,
                    "percent": percent,
                    "usedGb": usedBytes / 1e9,
                    "sizeGb": sizeBytes / 1e9
                  });
      }
      root.disks = out;
    }
  }

  Process {
    id: uptimeProc
    command: ["sh", "-c", "cat /proc/uptime; cat /proc/loadavg"]
    stdout: StdioCollector {
      id: uptimeCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      var lines = uptimeCollector.text.trim().split("\n");
      var seconds = parseFloat((lines[0] || "0").split(" ")[0]) || 0;
      var d = Math.floor(seconds / 86400);
      var h = Math.floor((seconds % 86400) / 3600);
      var mi = Math.floor((seconds % 3600) / 60);
      root.uptimeText = (d > 0 ? d + "d " : "") + String(h).padStart(2, "0") + ":" + String(mi).padStart(2, "0");

      var loadParts = (lines[1] || "").trim().split(/\s+/);
      if (loadParts.length >= 3) {
        root.loadAvg1 = parseFloat(loadParts[0]) || 0;
        root.loadAvg5 = parseFloat(loadParts[1]) || 0;
        root.loadAvg15 = parseFloat(loadParts[2]) || 0;
      }
    }
  }

  Component.onCompleted: root.refreshStats()

  function toggle() {
    visible = !visible;
  }

  visible: false
  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-system-stats"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  // Per-screen IPC target ("systemStats_DP-1") so each monitor's icon reaches its own instance.
  IpcHandler {
    target: "systemStats_" + (root.targetScreen ? root.targetScreen.name : "0")
    function toggle() {
      root.toggle();
    }
    function open() {
      root.visible = true;
    }
    function openAt(x: real, y: real) {
      if (root.visible) {
        root.visible = false;
        return;
      }
      root.triggerPos = Qt.point(x, y);
      root.visible = true;
    }
    function close() {
      root.visible = false;
    }
  }

  // A plain "systemStats" alias on just one instance, for a keybind or
  // script that doesn't know/care which screen it's on.
  IpcHandler {
    enabled: root.targetScreen === Quickshell.screens[0]
    target: "systemStats"
    function toggle() {
      root.toggle();
    }
    function open() {
      root.visible = true;
    }
    function close() {
      root.visible = false;
    }
  }

  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.visible = false
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.visible = false
  }

  Item {
    id: card

    readonly property real _crossFallback: 12
    readonly property real _crossPos: {
      if (root._barLeft || root._barRight)
        return root._hasTrigger ? Math.max(8, Math.min(root._triggerY, root.height - card.height - 8)) : _crossFallback;
      return root._hasTrigger ? Math.max(8, Math.min(root._triggerX, root.width - card.width - 8)) : root.width - card.width - _crossFallback;
    }

    x: root._barLeft ? root._barOffset : (root._barRight ? root.width - card.width - root._barOffset : card._crossPos)
    y: root._barBottom ? root.height - card.height - root._barOffset : (root._barLeft || root._barRight ? card._crossPos : root._barOffset)
    width: 480
    height: column.implicitHeight + 28

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutTopRight: true
      cutBottomLeft: true
      fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
      strokeColor: Color.outline
      strokeWidth: Tokens.borderPanel
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      id: column
      anchors.fill: parent
      anchors.margins: 14
      spacing: 14

      // ---- Header ----
      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Text {
          text: "SYSTEM STATS"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.weight: Tokens.labelXsWeight
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }

        Item {
          Layout.fillWidth: true
        }

        Text {
          text: "Uptime " + root.uptimeText
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.captionSize
        }

        Text {
          text: "×"
          color: closeHover.hovered ? Color.surfaceText : Color.labelText
          font.pixelSize: Tokens.bodyLgSize

          HoverHandler {
            id: closeHover
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: root.visible = false
          }
        }
      }

      // ---- CPU + MEM + TEMP dials ----
      RowLayout {
        Layout.fillWidth: true
        spacing: 18

        CircularGauge {
          percent: root.cpuPercent
          value: Math.round(root.cpuPercent) + "%"
          label: "CPU"
        }
        CircularGauge {
          percent: root.memPercent
          value: root.memUsedGb.toFixed(1) + "G"
          label: "MEM"
        }
        CircularGauge {
          percent: Math.min(100, root.tempC)
          fillColor: Color.tertiary
          value: Math.round(root.tempC) + "°"
          label: "TEMP"
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 2
          Text {
            text: "MEM " + root.memUsedGb.toFixed(1) + " / " + root.memTotalGb.toFixed(1) + " GB"
            color: Color.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodySmSize
          }
          Text {
            text: "LOAD " + root.loadAvg1.toFixed(2) + " • " + root.loadAvg5.toFixed(2) + " • " + root.loadAvg15.toFixed(2)
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.captionSize
          }
        }
      }

      // ---- Per-core CPU breakdown ----
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        visible: root.coresUsage.length > 0

        Text {
          text: "CORES (" + root.coresUsage.length + ")"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }

        Item {
          id: coreChart
          Layout.fillWidth: true
          Layout.preferredHeight: 32

          Row {
            anchors.fill: parent
            spacing: 3

            Repeater {
              model: root.coresUsage.length

              delegate: Item {
                required property int index
                width: Math.max(2, (coreChart.width - (root.coresUsage.length - 1) * 3) / root.coresUsage.length)
                height: coreChart.height

                Rectangle {
                  anchors.bottom: parent.bottom
                  width: parent.width
                  height: Math.max(2, parent.height * (Math.min(100, root.coresUsage[index]) / 100))
                  color: root.coresUsage[index] >= 85 ? Color.error : Color.primary

                  Behavior on height {
                    NumberAnimation {
                      duration: Tokens.durationMeterFill
                      easing.type: Tokens.easingMeterFill
                    }
                  }
                }
              }
            }
          }
        }
      }

      // ---- Disk: every real mounted filesystem ----
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 8
        visible: root.disks.length > 0

        Text {
          text: "DISK"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }

        Repeater {
          model: root.disks

          delegate: ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
              Layout.fillWidth: true
              Text {
                text: modelData.target
                color: Color.surfaceText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.bodySmSize
                elide: Text.ElideMiddle
                Layout.fillWidth: true
              }
              Text {
                text: modelData.usedGb.toFixed(1) + " / " + modelData.sizeGb.toFixed(1) + " GB (" + modelData.percent + "%)"
                color: Color.labelText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.captionSize
              }
            }

            SegMeter {
              Layout.fillWidth: true
              cellCount: Tokens.meterTelemetryCells
              cellHeight: Tokens.meterTelemetryCellHeight
              value: modelData.percent
              interactive: false
              filledColor: modelData.percent >= 90 ? Color.error : Color.primary
              emptyColor: Color.surfaceContainerHigh
            }
          }
        }
      }
    }
  }
}
