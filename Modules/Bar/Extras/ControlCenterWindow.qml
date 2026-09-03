import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// Control Center. Only rows with real backing are wired up; unimplemented ones (night light, recording, color-picker) show disabled, not omitted.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  // Direct in-process handle for callers on this screen (see Commons/Popups.qml).
  PopupRegistration {
    name: "controlCenter"
    surface: root
    screen: root.targetScreen
  }

  readonly property string _barPos: Settings.isLoaded ? Settings.getBarPositionForScreen(root.targetScreen ? root.targetScreen.name : "") : "top"
  readonly property bool _barLeft: root._barPos === "left"
  readonly property bool _barRight: root._barPos === "right"
  readonly property bool _barBottom: root._barPos === "bottom"
  readonly property bool _barTop: !root._barLeft && !root._barRight && !root._barBottom
  readonly property real _barOffset: Settings.data.bar.thickness + Settings.data.bar.floatMargin

  // Bar-icon trigger position, mapped into this popup's space; -1 = not set (IPC open). See SoundMenuWindow.qml.
  property point triggerPos: Qt.point(-1, -1)
  readonly property bool _hasTrigger: triggerPos.x >= 0
  readonly property real _triggerX: triggerPos.x + Settings.data.bar.floatMargin
  readonly property real _triggerY: triggerPos.y + Settings.data.bar.floatMargin

  // ---- Wifi ----
  readonly property var wifiDevice: {
    var devices = Networking.devices ? Networking.devices.values : [];
    for (var i = 0; i < devices.length; i++) {
      if (devices[i] && devices[i].type === DeviceType.Wifi)
        return devices[i];
    }
    return null;
  }
  readonly property var connectedNetwork: {
    var networks = wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : [];
    for (var i = 0; i < networks.length; i++) {
      if (networks[i] && networks[i].connected)
        return networks[i];
    }
    return null;
  }

  // ---- Bluetooth ----
  readonly property var btAdapter: Bluetooth.defaultAdapter
  readonly property var btConnectedDevice: {
    var devices = Bluetooth.devices ? Bluetooth.devices.values : [];
    for (var i = 0; i < devices.length; i++)
      if (devices[i] && devices[i].connected)
        return devices[i];
    return null;
  }

  // ---- Audio: sink (volume) + source (mic) ----
  readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
  readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
  readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
  readonly property var source: Pipewire.ready ? Pipewire.defaultAudioSource : null
  readonly property bool micMuted: source && source.audio ? source.audio.muted : false

  PwObjectTracker {
    objects: [root.sink, root.source].filter(n => !!n)
  }

  // ---- Brightness (only if a backlight device exists) ----
  property bool hasBacklight: false
  property real brightnessPercent: 0

  function refreshBrightness() {
    brightnessProc.running = true;
  }

  Process {
    id: brightnessProc
    command: ["sh", "-c", "brightnessctl -m -c backlight 2>/dev/null | head -1"]
    stdout: StdioCollector {
      id: brightnessCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      var line = brightnessCollector.text.trim();
      if (!line) {
        root.hasBacklight = false;
        return;
      }
      var parts = line.split(",");
      root.hasBacklight = true;
      root.brightnessPercent = parseInt(parts[3]) || 0;
    }
  }

  function setBrightness(pct) {
    var clamped = Math.max(1, Math.min(100, Math.round(pct)));
    root.brightnessPercent = clamped;
    Quickshell.execDetached(["brightnessctl", "set", clamped + "%"]);
  }

  // ---- Idle inhibit ----
  // Needs a window to attach to, so it lives here rather than in the
  // service; the service still owns the state.
  IdleInhibitor {
    window: root
    enabled: IdleInhibitorService.active
  }

  // ---- User@host + uptime ----
  property string whoHost: "…"
  property string uptimeText: "…"

  Process {
    id: whoProc
    command: ["sh", "-c", "echo \"$(whoami)@$(uname -n)\""]
    stdout: StdioCollector {
      id: whoCollector
      waitForEnd: true
    }
    onExited: exitCode => root.whoHost = whoCollector.text.trim()
  }

  Process {
    id: uptimeProc
    command: ["cat", "/proc/uptime"]
    stdout: StdioCollector {
      id: uptimeCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      var seconds = parseFloat(uptimeCollector.text.split(" ")[0]) || 0;
      var d = Math.floor(seconds / 86400);
      var h = Math.floor((seconds % 86400) / 3600);
      var m = Math.floor((seconds % 3600) / 60);
      root.uptimeText = (d > 0 ? d + "D " : "") + String(h).padStart(2, "0") + ":" + String(m).padStart(2, "0");
    }
  }

  // ---- Telemetry: CPU / MEM / TEMP / DISK ----
  property real cpuPercent: 0
  property real memPercent: 0
  property real memUsedGb: 0
  property real tempC: 0
  property real diskPercent: 0
  property var _prevCpuStats: null

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

  function refreshStats() {
    statProc.running = true;
    sensorsProc.running = true;
    diskProc.running = true;
  }

  Timer {
    interval: Settings.data.controlCenter.statsRefreshInterval
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      root.refreshStats();
      uptimeProc.running = true;
    }
  }

  Process {
    id: statProc
    command: ["sh", "-c", "head -1 /proc/stat; grep -E 'MemTotal|MemAvailable' /proc/meminfo"]
    stdout: StdioCollector {
      id: statCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      var lines = statCollector.text.split("\n");
      var cur = root._calcUsage(lines[0] || "");
      if (root._prevCpuStats) {
        var dTotal = cur.total - root._prevCpuStats.total;
        var dIdle = cur.idle - root._prevCpuStats.idle;
        root.cpuPercent = dTotal > 0 ? Math.max(0, Math.min(100, 100 * (1 - dIdle / dTotal))) : root.cpuPercent;
      }
      root._prevCpuStats = cur;

      var memTotal = 0, memAvail = 0;
      for (var i = 1; i < lines.length; i++) {
        var m = lines[i].match(/(\d+)/);
        if (!m)
          continue;
        if (lines[i].indexOf("MemTotal") === 0)
          memTotal = parseInt(m[1]);
        else if (lines[i].indexOf("MemAvailable") === 0)
          memAvail = parseInt(m[1]);
      }
      root.memPercent = memTotal > 0 ? Math.max(0, Math.min(100, 100 * (1 - memAvail / memTotal))) : root.memPercent;
      root.memUsedGb = (memTotal - memAvail) / (1024 * 1024);
    }
  }

  // k10temp's Tctl is the standard AMD CPU control-temp sensor; falls back
  // to the first temp1_input `sensors -j` reports on non-AMD boxes.
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

  Process {
    id: diskProc
    command: ["sh", "-c", "df --output=pcent / | tail -1"]
    stdout: StdioCollector {
      id: diskCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      var m = diskCollector.text.match(/(\d+)/);
      if (m)
        root.diskPercent = parseInt(m[1]);
    }
  }

  // ---- Media (real MPRIS, same pattern as MediaPlayerWindow.qml) ----
  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var activePlayer: {
    var preferred = Settings.isLoaded ? Settings.data.audio.preferredMediaPlayer : "";
    if (preferred !== "") {
      for (var j = 0; j < players.length; j++)
        if (players[j] && players[j].identity === preferred)
          return players[j];
    }
    for (var i = 0; i < players.length; i++) {
      if (players[i] && players[i].playbackState === MprisPlaybackState.Playing)
        return players[i];
    }
    return players.length > 0 ? players[0] : null;
  }
  readonly property bool isPlaying: activePlayer ? activePlayer.playbackState === MprisPlaybackState.Playing : false
  property int _positionTick: 0
  readonly property real mediaPosition: {
    _positionTick;
    return activePlayer ? activePlayer.position : 0;
  }
  readonly property real mediaLength: activePlayer ? activePlayer.length : 0

  Timer {
    interval: 1000
    running: root.visible && root.isPlaying
    repeat: true
    onTriggered: root._positionTick++
  }

  // ---- Action-grid tool availability (shown disabled, never faked) ----
  property bool hasRecorder: false
  property bool hasColorPicker: false

  Process {
    id: toolCheckProc
    command: ["sh", "-c", "command -v wf-recorder >/dev/null && echo rec=1; command -v hyprpicker >/dev/null && echo pick=1"]
    stdout: StdioCollector {
      id: toolCheckCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      root.hasRecorder = toolCheckCollector.text.indexOf("rec=1") !== -1;
      root.hasColorPicker = toolCheckCollector.text.indexOf("pick=1") !== -1;
    }
  }

  Component.onCompleted: {
    whoProc.running = true;
    uptimeProc.running = true;
    root.refreshBrightness();
    root.refreshStats();
    toolCheckProc.running = true;
  }

  function toggle() {
    visible = !visible;
  }
  function open() {
    visible = true;
  }
  function close() {
    visible = false;
  }
  // Carries the triggering icon's own position (see triggerPos) so the
  // popup can line up with it instead of a generic corner.
  function openAt(x, y) {
    if (visible) {
      visible = false;
      return;
    }
    triggerPos = Qt.point(x, y);
    visible = true;
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
  WlrLayershell.namespace: "crux-control-center"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  // Per-screen IPC target name ("controlCenter_DP-1") so each monitor's icon reaches its own instance, not screen 0's.
  IpcHandler {
    target: "controlCenter_" + (root.targetScreen ? root.targetScreen.name : "0")
    function toggle() {
      root.toggle();
    }
    function open() {
      root.open();
    }
    function openAt(x: real, y: real) {
      root.openAt(x, y);
    }
    function close() {
      root.close();
    }
  }

  // WIFI/BLUETOOTH tiles' right-click "expand" state; renders the shared panel content inline instead of a popup.
  property bool wifiExpanded: false
  property bool btExpanded: false

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
    // Cross-axis position (along the bar's own length): lines up with the
    // triggering icon when known, clamped on-screen; falls back to the old
    // fixed near-corner inset otherwise. Main-axis position (the gap
    // between the bar and the popup) always uses _barOffset, unchanged.
    readonly property real _crossFallback: 12
    readonly property real _crossPos: {
      if (root._barLeft || root._barRight)
        return root._hasTrigger ? Math.max(8, Math.min(root._triggerY, root.height - card.height - 8)) : _crossFallback;
      return root._hasTrigger ? Math.max(8, Math.min(root._triggerX, root.width - card.width - 8)) : root.width - card.width - _crossFallback;
    }

    x: root._barLeft ? root._barOffset : (root._barRight ? root.width - card.width - root._barOffset : card._crossPos)
    y: root._barBottom ? root.height - card.height - root._barOffset : (root._barLeft || root._barRight ? card._crossPos : root._barOffset)
    width: 436
    height: column.implicitHeight + 28

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      // Flush against the bar, so cut only the two corners on the far
      // side from it -- the near side reads as growing out of the bar
      // instead of floating as a fully separate chamfered card.
      cutTopLeft: root._barBottom || root._barRight
      cutTopRight: root._barBottom || root._barLeft
      cutBottomLeft: root._barTop || root._barRight
      cutBottomRight: root._barTop || root._barLeft
      omitStrokeSide: root._barBottom ? "bottom" : (root._barLeft ? "left" : (root._barRight ? "right" : "top"))
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
      spacing: 12

      // ---- Header: Arch logo avatar + user/uptime + gear/power/close ----
      // Circular avatar/buttons here are a deliberate one-off departure
      // from the rest of the app's "no radius" rule — explicitly requested
      // to match a specific reference look, scoped to this one panel.
      CcCard {
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Item {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40

            Rectangle {
              anchors.fill: parent
              radius: width / 2
              color: Color.surfaceContainer
              border.color: Color.outline
              border.width: Tokens.borderModule
              clip: true

              Image {
                anchors.fill: parent
                visible: Settings.data.general.avatarImage !== ""
                source: Settings.data.general.avatarImage !== "" ? "file://" + Settings.data.general.avatarImage : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
              }
            }
            ArchLogo {
              visible: Settings.data.general.avatarImage === ""
              anchors.centerIn: parent
              width: 22
              height: 22
            }
          }

          ColumnLayout {
            spacing: 0
            NText {
              text: root.whoHost
              color: Color.surfaceText
              size: NText.Size.BodyLg
              font.weight: Font.DemiBold
            }
            NText {
              text: "Uptime: " + root.uptimeText
              color: Color.labelText
              size: NText.Size.Caption
            }
          }

          Item {
            Layout.fillWidth: true
          }

          CcCircleToggle {
            implicitWidth: 32
            implicitHeight: 32
            onTapped: {
              root.visible = false;
              Popups.open("settings", root.targetScreen);
            }
            IconImage {
              anchors.centerIn: parent
              width: 16
              height: 16
              source: Quickshell.iconPath("preferences-system-symbolic", "applications-system-symbolic")
            }
          }

          CcCircleToggle {
            implicitWidth: 32
            implicitHeight: 32
            onTapped: {
              root.visible = false;
              Popups.open("power", root.screen);
            }
            IconImage {
              anchors.centerIn: parent
              width: 16
              height: 16
              source: Quickshell.iconPath("system-shutdown-symbolic")
            }
          }

          CcCircleToggle {
            implicitWidth: 32
            implicitHeight: 32
            onTapped: root.visible = false
            IconImage {
              anchors.centerIn: parent
              width: 14
              height: 14
              source: Quickshell.iconPath("window-close-symbolic")
            }
          }
        }
      }

      // ---- Toggle row: real radios only (Wifi/Bluetooth/Mic/Night Light) ----
      CcCard {
        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          CcCircleToggle {
            id: wifiTile
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            active: Networking.wifiEnabled
            onTapped: {
              root.btExpanded = false;
              root.wifiExpanded = !root.wifiExpanded;
            }
            IconImage {
              anchors.centerIn: parent
              width: 18
              height: 18
              source: Quickshell.iconPath(wifiTile.active ? "network-wireless-symbolic" : "network-wireless-disconnected-symbolic")
            }
          }

          CcCircleToggle {
            id: btTile
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            active: root.btAdapter && root.btAdapter.enabled
            available: !!root.btAdapter
            onTapped: {
              root.wifiExpanded = false;
              root.btExpanded = !root.btExpanded;
            }
            IconImage {
              anchors.centerIn: parent
              width: 16
              height: 16
              source: Quickshell.iconPath(btTile.active ? "preferences-system-bluetooth-activated-symbolic" : "preferences-system-bluetooth-inactive-symbolic")
            }
          }

          CcCircleToggle {
            id: micTile
            active: root.source && !root.micMuted
            available: !!root.source
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            onTapped: if (root.source && root.source.audio)
              root.source.audio.muted = !root.source.audio.muted
            IconImage {
              anchors.centerIn: parent
              width: 16
              height: 16
              source: Quickshell.iconPath(micTile.active ? "audio-input-microphone-symbolic" : "microphone-sensitivity-muted-symbolic")
            }
          }

          CcCircleToggle {
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            available: false
            IconImage {
              anchors.centerIn: parent
              width: 16
              height: 16
              source: Quickshell.iconPath("weather-clear-night-symbolic")
            }
          }

          Item {
            Layout.fillWidth: true
          }
        }
      }

      // ---- Inline WIFI/BLUETOOTH expand (right-click a toggle above) —
      // full network/device list rendered right here instead of opening a
      // separate popup window, sharing the exact same components the
      // standalone Wifi.qml/Bluetooth.qml bar widgets use. ----
      WifiPanelContent {
        Layout.fillWidth: true
        visible: root.wifiExpanded
        panelActive: root.wifiExpanded
        onRequestClose: root.wifiExpanded = false
      }
      BluetoothPanelContent {
        Layout.fillWidth: true
        visible: root.btExpanded
        panelActive: root.btExpanded
      }

      // ---- Audio: two sliders, each labeled with the real device name ----
      CcCard {
        RowLayout {
          Layout.fillWidth: true
          spacing: 14

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            NText {
              text: root.sink ? (root.sink.description || root.sink.name || "Output") : "No output"
              color: Color.labelText
              size: NText.Size.Caption
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
            SegMeter {
              Layout.fillWidth: true
              cellCount: Tokens.meterControlCenterCells
              cellHeight: Tokens.meterControlCenterCellHeight
              value: root.muted ? 0 : root.volume * 100
              interactive: true
              filledColor: Color.primary
              emptyColor: Color.surfaceContainerHigh
              onMoved: pct => {
                if (root.sink && root.sink.audio) {
                  root.sink.audio.volume = pct / 100;
                  if (pct > 0)
                    root.sink.audio.muted = false;
                }
              }
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            NText {
              text: root.source ? (root.source.description || root.source.name || "Input") : "No input"
              color: Color.labelText
              size: NText.Size.Caption
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
            SegMeter {
              Layout.fillWidth: true
              cellCount: Tokens.meterControlCenterCells
              cellHeight: Tokens.meterControlCenterCellHeight
              value: root.source && root.source.audio ? root.source.audio.volume * 100 : 0
              interactive: !!root.source
              filledColor: Color.primary
              emptyColor: Color.surfaceContainerHigh
              onMoved: pct => {
                if (root.source && root.source.audio)
                  root.source.audio.volume = pct / 100;
              }
            }
          }
        }
      }

      // ---- BRI slider (only if a backlight device exists) ----
      CcCard {
        CcSlider {
          Layout.fillWidth: true
          visible: root.hasBacklight
          label: "BRI"
          value: root.brightnessPercent
          onMoved: pct => root.setBrightness(pct)
        }
        RowLayout {
          Layout.fillWidth: true
          visible: !root.hasBacklight
          NText {
            text: "Brightness"
            color: Color.disabledText
            size: NText.Size.BodySm
            Layout.fillWidth: true
          }
          NText {
            text: "n/a"
            color: Color.disabledText
            size: NText.Size.Caption
          }
        }

      }
      // ---- Weather (real: ip-api.com geolocation + open-meteo forecast,
      // see Commons/Weather.qml) ----
      CcCard {
        ColumnLayout {
          Layout.fillWidth: true
          visible: Weather.ready && Settings.data.controlCenter.showWeather
          spacing: 10

          RowLayout {
            Layout.fillWidth: true
            spacing: 10
            WeatherIcon {
              Layout.preferredWidth: 40
              Layout.preferredHeight: 40
              category: Weather.iconCategory(Weather.currentWeatherCode)
            }
            ColumnLayout {
              spacing: 0
              NText {
                text: Weather.cityName
                color: Color.surfaceText
                font.weight: Font.DemiBold
              }
              RowLayout {
                spacing: 6
                NText {
                  text: Math.round(Weather.currentTempF) + Weather.unitSuffix
                  color: Color.surfaceText
                  size: NText.Size.BodySm
                }
                NText {
                  text: "(" + Weather.gmtOffsetLabel + ")"
                  color: Color.labelText
                  size: NText.Size.Caption
                }
              }
            }
            Item {
              Layout.fillWidth: true
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 4
            Repeater {
              model: Weather.daily
              delegate: ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 2
                NText {
                  tracking: true
                  Layout.alignment: Qt.AlignHCenter
                  text: modelData.dayName.toUpperCase()
                  color: Color.labelText
                  font.pixelSize: Tokens.labelXsSize - 1
                  font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
                }
                WeatherIcon {
                  Layout.alignment: Qt.AlignHCenter
                  Layout.preferredWidth: 22
                  Layout.preferredHeight: 22
                  category: Weather.iconCategory(modelData.weatherCode)
                }
                NText {
                  Layout.alignment: Qt.AlignHCenter
                  text: modelData.tempMaxF + "°/" + modelData.tempMinF + "°"
                  color: Color.surfaceTextMuted
                  font.pixelSize: Tokens.labelXsSize - 1
                }
              }
            }
          }
        }
      }

      // ---- Media (left, real MPRIS) + telemetry dials (right) ----
      CcCard {
        RowLayout {
          Layout.fillWidth: true
          spacing: 14

          ColumnLayout {
            Layout.fillWidth: true
            visible: !!root.activePlayer
            spacing: 6

            NText {
              text: root.activePlayer ? root.activePlayer.identity : ""
              color: Color.labelText
              size: NText.Size.Caption
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
            NText {
              text: root.activePlayer ? root.activePlayer.trackTitle : ""
              color: Color.surfaceText
              size: NText.Size.BodySm
              font.weight: Font.DemiBold
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
            SegMeter {
              Layout.fillWidth: true
              cellCount: Tokens.meterSidebarSeekCells
              cellHeight: Tokens.meterSidebarSeekCellHeight
              value: root.mediaLength > 0 ? (root.mediaPosition / root.mediaLength) * 100 : 0
              interactive: !!root.activePlayer && root.activePlayer.canSeek
              filledColor: Color.primary
              emptyColor: Color.surfaceContainerHigh
              onMoved: pct => {
                if (root.activePlayer && root.activePlayer.canSeek)
                  root.activePlayer.position = (pct / 100) * root.mediaLength;
              }
            }
            Item {
              Layout.preferredHeight: 30
              Layout.alignment: Qt.AlignHCenter

              Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: root.isPlaying ? Color.primary : Color.surfaceContainer
              }
              Text {
                anchors.centerIn: parent
                text: root.isPlaying ? "⏸" : "▶"
                color: root.isPlaying ? Color.surface : Color.surfaceText
                font.pixelSize: 13
              }
              HoverHandler {
                cursorShape: Qt.PointingHandCursor
              }
              TapHandler {
                enabled: !!root.activePlayer && (root.activePlayer.canPlay || root.activePlayer.canPause)
                onTapped: root.activePlayer.togglePlaying()
              }
              width: 60
            }
          }

          NText {
            visible: !root.activePlayer
            text: "No media playing"
            color: Color.disabledText
            size: NText.Size.BodySm
            Layout.fillWidth: true
          }

          Grid {
            columns: 2
            rowSpacing: 4
            columnSpacing: 4

            CircularGauge {
              percent: root.cpuPercent
              value: Math.round(root.cpuPercent) + "%"
              label: "CPU"
            }
            CircularGauge {
              percent: Math.min(100, root.tempC)
              fillColor: Color.tertiary
              value: Math.round(root.tempC) + "°"
              label: "TEMP"
            }
            CircularGauge {
              percent: root.memPercent
              value: root.memUsedGb.toFixed(1) + "G"
              label: "MEM"
            }
            CircularGauge {
              percent: root.diskPercent
              value: Math.round(root.diskPercent) + "%"
              label: "DISK"
            }
          }
        }
      }

      // ---- Action row: still real, still not fabricated ----
      CcCard {
        GridLayout {
          Layout.fillWidth: true
          columns: 3
          rowSpacing: 1
          columnSpacing: 1

          CcActionButton {
            Layout.fillWidth: true
            label: "CAPTURE"
            icon: "camera-photo-symbolic"
            onTapped: {
              root.visible = false;
              Quickshell.execDetached(["sh", "-c", Settings.data.controlCenter.screenshotCommand]);
            }
          }
          CcActionButton {
            Layout.fillWidth: true
            label: "RECORD"
            icon: "media-record-symbolic"
            available: root.hasRecorder
          }
          CcActionButton {
            Layout.fillWidth: true
            label: "COLOR"
            icon: "color-select-symbolic"
            available: root.hasColorPicker
          }
          CcActionButton {
            Layout.fillWidth: true
            label: "WALLPAPER"
            icon: "preferences-desktop-wallpaper"
            onTapped: {
              root.visible = false;
              Popups.openTab("settings", root.targetScreen, "wallpaper");
            }
          }
          CcActionButton {
            Layout.fillWidth: true
            label: IdleInhibitorService.active ? "IDLE ON" : "IDLE OFF"
            active: IdleInhibitorService.active
            onTapped: IdleInhibitorService.toggle()
          }
          CcActionButton {
            Layout.fillWidth: true
            label: "SETTINGS"
            icon: "preferences-system-symbolic"
            onTapped: {
              root.visible = false;
              Popups.open("settings", root.targetScreen);
            }
          }
        }
      }
    }
  }
}
