import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.Commons
import qs.Modules.ControlCenter
import qs.Services
import qs.Widgets

// Control Center content: cards for the quick toggles, audio and brightness
// sliders, weather, media and telemetry. The card layout follows noctalia's,
// the chamfers are crux's own — see the crux skill's notes.md for why that
// deliberately diverges from the spec PDF.
ColumnLayout {
  id: root

  spacing: Tokens.spaceLg

  // Set from the card's shown state; system stats are sampled only while open.
  property bool active: false
  onActiveChanged: SystemStats.fullWatchers += active ? 1 : -1
  Component.onDestruction: if (active)
    SystemStats.fullWatchers--
  // Which monitor this card is on, for the Popups calls that open another
  // surface on the same screen.
  property var targetScreen: null
  // PopupHost closes the card; the content can't reach a window's visible
  // any more.
  signal requestClose

  // WIFI/BLUETOOTH tiles' right-click "expand" state; renders the shared
  // panel content inline instead of opening a separate popup.
  property bool wifiExpanded: false
  property bool btExpanded: false

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
  readonly property string uptimeText: SystemStats.formatUptime("D")

  Process {
    id: whoProc
    command: ["sh", "-c", "echo \"$(whoami)@$(uname -n)\""]
    stdout: StdioCollector {
      id: whoCollector
      waitForEnd: true
    }
    onExited: exitCode => root.whoHost = whoCollector.text.trim()
  }

  // ---- Telemetry: CPU / MEM / TEMP / DISK ----
  readonly property real cpuPercent: SystemStats.cpuPercent
  readonly property real memPercent: SystemStats.memPercent
  readonly property real memUsedGb: SystemStats.memUsedGb
  readonly property real tempC: SystemStats.tempC
  readonly property real diskPercent: SystemStats.rootDiskPercent

  // ---- Media ----
  readonly property var activePlayer: MediaService.activePlayer
  readonly property bool isPlaying: MediaService.isPlaying
  readonly property real mediaPosition: MediaService.position
  readonly property real mediaLength: MediaService.length

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
    root.refreshBrightness();
    toolCheckProc.running = true;
  }


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
          color: Colors.surfaceContainer
          border.color: Colors.outline
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
          color: Colors.surfaceText
          size: NText.Size.BodyLg
          font.weight: Font.DemiBold
        }
        NText {
          text: "Uptime: " + root.uptimeText
          color: Colors.labelText
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
          root.requestClose();
          Popups.open("settings", root.targetScreen);
        }
        NIcon {
          anchors.centerIn: parent
          width: 16
          height: 16
          iconName: "preferences-system-symbolic"
          fallbackIconName: "preferences-system"
          color: Colors.surfaceText
        }
      }

      CcCircleToggle {
        implicitWidth: 32
        implicitHeight: 32
        onTapped: {
          root.requestClose();
          Popups.open("power", root.targetScreen);
        }
        NIcon {
          anchors.centerIn: parent
          width: 16
          height: 16
          iconName: "system-shutdown-symbolic"
          fallbackIconName: "system-shutdown"
          color: Colors.surfaceText
        }
      }

      CcCircleToggle {
        implicitWidth: 32
        implicitHeight: 32
        onTapped: root.requestClose()
        NIcon {
          anchors.centerIn: parent
          width: 14
          height: 14
          iconName: "window-close-symbolic"
          fallbackIconName: "window-close"
          color: Colors.surfaceText
        }
      }
    }
  }

  // ---- Toggle row: configurable, from Settings.data.controlCenter.toggles
  // (ids in CcToggleRegistry, files in CcToggles/) ----
  CcCard {
    RowLayout {
      Layout.fillWidth: true
      spacing: 10

      Repeater {
        model: Settings.data.controlCenter.toggles

        // Each toggle centered in an equal share of the row.
        delegate: Item {
          id: toggleSlot
          required property string modelData
          Layout.fillWidth: true
          Layout.preferredHeight: 40

          Loader {
            id: toggleLoader
            anchors.centerIn: parent
            width: 40
            height: 40
            active: CcToggleRegistry.has(toggleSlot.modelData)
            source: CcToggleRegistry.sourceFor(toggleSlot.modelData)
          }

          Connections {
            target: toggleLoader.item
            ignoreUnknownSignals: true
            function onExpandRequested(which) {
              // Only one list can be open at a time, and tapping the
              // same toggle again closes it.
              if (which === "wifi") {
                root.btExpanded = false;
                root.wifiExpanded = !root.wifiExpanded;
              } else if (which === "bluetooth") {
                root.wifiExpanded = false;
                root.btExpanded = !root.btExpanded;
              }
            }
          }
        }
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
          color: Colors.labelText
          size: NText.Size.Caption
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
        CcLevelSlider {
          Layout.fillWidth: true
          value: root.muted ? 0 : root.volume * 100
          interactive: true
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
          color: Colors.labelText
          size: NText.Size.Caption
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
        CcLevelSlider {
          Layout.fillWidth: true
          value: root.source && root.source.audio ? root.source.audio.volume * 100 : 0
          interactive: !!root.source
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
    visible: root.hasBacklight
    CcSlider {
      Layout.fillWidth: true
      label: "BRI"
      value: root.brightnessPercent
      onMoved: pct => root.setBrightness(pct)
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
            color: Colors.surfaceText
            font.weight: Font.DemiBold
          }
          RowLayout {
            spacing: 6
            NText {
              text: Math.round(Weather.currentTempF) + Weather.unitSuffix
              color: Colors.surfaceText
              size: NText.Size.BodySm
            }
            NText {
              text: "(" + Weather.gmtOffsetLabel + ")"
              color: Colors.labelText
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
          // Item wrapper: a ColumnLayout won't grow past its children.
          delegate: Item {
            id: dayCell
            required property var modelData
            Layout.fillWidth: true
            implicitWidth: dayCol.implicitWidth
            implicitHeight: dayCol.implicitHeight

            ColumnLayout {
              id: dayCol
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: 2
              NText {
                tracking: true
                Layout.alignment: Qt.AlignHCenter
                text: dayCell.modelData.dayName.toUpperCase()
                color: Colors.labelText
                font.pixelSize: Tokens.labelXsSize - 1
                font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
              }
              WeatherIcon {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                category: Weather.iconCategory(dayCell.modelData.weatherCode)
              }
              NText {
                Layout.alignment: Qt.AlignHCenter
                text: dayCell.modelData.tempMaxF + "°/" + dayCell.modelData.tempMinF + "°"
                color: Colors.surfaceTextMuted
                font.pixelSize: Tokens.labelXsSize - 1
              }
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
          color: Colors.labelText
          size: NText.Size.Caption
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
        NText {
          text: root.activePlayer ? root.activePlayer.trackTitle : ""
          color: Colors.surfaceText
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
          filledColor: Colors.primary
          emptyColor: Colors.surfaceContainerHigh
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
            color: root.isPlaying ? Colors.primary : Colors.surfaceContainer
          }
          Text {
            anchors.centerIn: parent
            text: root.isPlaying ? "⏸" : "▶"
            color: root.isPlaying ? Colors.surface : Colors.surfaceText
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

      // No player: the dials take the whole card as one row.
      Grid {
        id: gauges
        Layout.fillWidth: !root.activePlayer
        columns: root.activePlayer ? 2 : 4
        rowSpacing: 4
        columnSpacing: root.activePlayer ? 4 : Math.max(4, (parent.width - 4 * 52) / 3)

        CircularGauge {
          percent: root.cpuPercent
          value: Math.round(root.cpuPercent) + "%"
          label: "CPU"
        }
        CircularGauge {
          percent: Math.min(100, root.tempC)
          fillColor: Colors.tertiary
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
        iconFallback: "camera-photo"
        onTapped: {
          root.requestClose();
          Quickshell.execDetached(["sh", "-c", Settings.data.controlCenter.screenshotCommand]);
        }
      }
      CcActionButton {
        Layout.fillWidth: true
        label: "RECORD"
        icon: "media-record-symbolic"
        iconFallback: "media-record"
        iconColor: Colors.error
        available: root.hasRecorder
      }
      CcActionButton {
        Layout.fillWidth: true
        label: "COLOR"
        icon: "color-select-symbolic"
        iconFallback: "color-select"
        available: root.hasColorPicker
      }
      CcActionButton {
        Layout.fillWidth: true
        label: "WALLPAPER"
        icon: "desktop-symbolic"
        iconFallback: "preferences-desktop-wallpaper"
        onTapped: {
          root.requestClose();
          Popups.openTab("settings", root.targetScreen, "wallpaper");
        }
      }
      CcActionButton {
        Layout.fillWidth: true
        label: IdleInhibitorService.active ? "IDLE ON" : "IDLE OFF"
        icon: IdleInhibitorService.active ? "view-visible-symbolic" : "view-visible-off-symbolic"
        iconFallback: IdleInhibitorService.active ? "view-visible" : "view-visible-off"
        active: IdleInhibitorService.active
        onTapped: IdleInhibitorService.toggle()
      }
      CcActionButton {
        Layout.fillWidth: true
        label: "SETTINGS"
        icon: "preferences-system-symbolic"
        iconFallback: "preferences-system"
        onTapped: {
          root.requestClose();
          Popups.open("settings", root.targetScreen);
        }
      }
    }
  }
}
