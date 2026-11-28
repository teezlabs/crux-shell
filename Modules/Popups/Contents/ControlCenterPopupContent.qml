import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.Commons
import qs.Modules.ControlCenter
import qs.Modules.Popups
import qs.Services
import qs.Widgets

// Control Center: profile and shortcuts, labelled toggle tiles, audio, media, weather, stats and recent notifications.
// The Wi-Fi and Bluetooth chevrons slide the panel to a sub-page; the card follows the current page's height.
Item {
  id: root

  implicitHeight: root.page === "" ? mainPage.implicitHeight : subPage.implicitHeight

  // Set from the card's shown state; system stats are sampled only while open.
  property bool active: false
  // System stats, Tailscale and the homelab pings are sampled only while open.
  onActiveChanged: {
    if (!active)
      root.page = "";
    const step = active ? 1 : -1;
    SystemStats.fullWatchers += step;
    Tailscale.watchers += step;
    Homelab.watchers += step;
  }
  Component.onDestruction: if (active) {
    SystemStats.fullWatchers--;
    Tailscale.watchers--;
    Homelab.watchers--;
  }
  // This card's monitor, for opening other surfaces on the same screen.
  property var targetScreen: null
  // Asks PopupHost to close the card.
  signal requestClose

  // "" for the main page, else "wifi" or "bluetooth".
  property string page: ""
  // Height a sub-page may take; its list scrolls inside that.
  readonly property real subPageMax: 560

  function closeAndOpen(name) {
    root.requestClose();
    Popups.open(name, root.targetScreen);
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

  Process {
    id: brightnessProc
    command: ["sh", "-c", "brightnessctl -m -c backlight 2>/dev/null | head -1"]
    stdout: StdioCollector {
      id: brightnessCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      const line = brightnessCollector.text.trim();
      root.hasBacklight = line !== "";
      if (root.hasBacklight)
        root.brightnessPercent = parseInt(line.split(",")[3]) || 0;
    }
  }

  function setBrightness(pct) {
    const clamped = Math.max(1, Math.min(100, Math.round(pct)));
    root.brightnessPercent = clamped;
    Quickshell.execDetached(["brightnessctl", "set", clamped + "%"]);
  }

  // ---- Idle inhibit: needs a window, so it lives here; IdleInhibitorService owns the state ----
  IdleInhibitor {
    window: root
    enabled: IdleInhibitorService.active
  }

  // ---- User@host ----
  property string whoHost: "…"

  Process {
    id: whoProc
    command: ["sh", "-c", "echo \"$(whoami)@$(uname -n)\""]
    stdout: StdioCollector {
      id: whoCollector
      waitForEnd: true
    }
    onExited: exitCode => root.whoHost = whoCollector.text.trim()
  }

  // ---- Tools the shortcuts need (shown disabled when missing, never faked) ----
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

  // ---- Screen recording: the focused output to ~/Videos, stopped with SIGINT so the file is finalized ----
  property string recordingPath: ""

  Process {
    id: recorder
    onExited: exitCode => {
      if (root.recordingPath !== "")
        Toast.show("Recording saved to " + root.recordingPath.replace(Quickshell.env("HOME"), "~"), 4000);
      root.recordingPath = "";
    }
  }

  function toggleRecording() {
    if (recorder.running) {
      recorder.signal(2);
      return;
    }
    const dir = Quickshell.env("HOME") + "/Videos";
    root.recordingPath = dir + "/recording-" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".mp4";
    const output = root.targetScreen ? root.targetScreen.name : "";
    recorder.command = ["sh", "-c", "mkdir -p \"$1\" && exec wf-recorder " + (output !== "" ? "-o \"$3\" " : "") + "-f \"$2\"", "sh", dir, root.recordingPath, output];
    recorder.running = true;
    root.requestClose();
  }

  // What each CcShortcutRegistry id does.
  function runShortcut(id) {
    if (id === "Record") {
      root.toggleRecording();
      return;
    }
    root.requestClose();
    if (id === "Screenshot")
      Quickshell.execDetached(["sh", "-c", Settings.data.controlCenter.screenshotCommand]);
    else if (id === "ColorPicker")
      Quickshell.execDetached(["hyprpicker", "-a"]);
    else if (id === "Clipboard")
      Popups.open("clipboard", root.targetScreen);
    else if (id === "Wallpaper")
      Popups.openTab("settings", root.targetScreen, "wallpaper");
    else if (id === "Lock")
      Hooks.runSessionHook("lock", () => Quickshell.execDetached(["qs", "ipc", "-c", "crux", "call", "lockscreen", "lock"]));
    else if (id === "Launcher")
      Popups.open("launcher", root.targetScreen);
    else if (id === "Notifications")
      Popups.open("notificationHistory", root.targetScreen);
  }

  Component.onCompleted: {
    whoProc.running = true;
    brightnessProc.running = true;
    toolCheckProc.running = true;
  }

  // ---- Weather: WMO code to a symbol ----
  function weatherSymbol(code, isDay) {
    const cat = Weather.iconCategory(code);
    if (cat === "sun")
      return isDay ? "sunny" : "clear_night";
    if (cat === "partly")
      return isDay ? "partly_cloudy_day" : "partly_cloudy_night";
    if (cat === "fog")
      return "foggy";
    if (cat === "rain")
      return "rainy";
    if (cat === "snow")
      return "weather_snowy";
    if (cat === "storm")
      return "thunderstorm";
    return "cloud";
  }

  function ago(ts) {
    const s = Math.max(0, Math.round((Date.now() - ts) / 1000));
    if (s < 60)
      return "now";
    if (s < 3600)
      return Math.floor(s / 60) + "m";
    if (s < 86400)
      return Math.floor(s / 3600) + "h";
    return Math.floor(s / 86400) + "d";
  }

  // Re-evaluates the notification ages while open.
  property real now: Date.now()
  Timer {
    interval: 30000
    running: root.active
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = Date.now()
  }

  // Pages slide a short way sideways and fade: forward to a sub-page, back to the main one.
  ColumnLayout {
    id: mainPage
    width: root.width
    spacing: Tokens.spaceMd
    visible: opacity > 0
    opacity: root.page === "" ? 1 : 0
    x: root.page === "" ? 0 : -Tokens.spaceXl * 2

    Behavior on opacity {
      NumberAnimation {
        duration: Tokens.durationSidebarSlide
        easing.type: Tokens.easingSidebarSlide
      }
    }
    Behavior on x {
      NumberAnimation {
        duration: Tokens.durationSidebarSlide
        easing.type: Tokens.easingSidebarSlide
      }
    }

    // ======== Profile and shortcuts ========
    CcCard {
      spacing: Tokens.spaceLg

      RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spaceLg

        // Round avatar: a deliberate exception to the no-radius rule, scoped to this panel.
        Item {
          Layout.preferredWidth: 44
          Layout.preferredHeight: 44

          Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Colors.surfaceContainerHigh
            border.color: Colors.alpha(Colors.primary, 0.6)
            border.width: Tokens.borderMarker
            clip: true

            Image {
              anchors.fill: parent
              anchors.margins: Tokens.borderMarker
              visible: Settings.data.general.avatarImage !== ""
              source: Settings.data.general.avatarImage !== "" ? "file://" + Settings.data.general.avatarImage : ""
              sourceSize.width: 88
              sourceSize.height: 88
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
          Layout.fillWidth: true
          spacing: Tokens.spaceXs

          NText {
            Layout.fillWidth: true
            text: root.whoHost
            size: NText.Size.BodyLg
            font.weight: Font.DemiBold
          }
          RowLayout {
            spacing: Tokens.spaceSm
            NSymbol {
              name: "schedule"
              size: 14
              color: Colors.labelText
            }
            NText {
              text: "up " + SystemStats.uptimeText
              size: NText.Size.Caption
              color: Colors.labelText
            }
          }
        }

        CcIconButton {
          symbol: "settings"
          tooltip: "Settings"
          onTapped: root.closeAndOpen("settings")
        }
        CcIconButton {
          symbol: "power_settings_new"
          tooltip: "Session menu"
          tone: "error"
          onTapped: root.closeAndOpen("power")
        }
      }

      RowLayout {
        visible: Settings.data.controlCenter.shortcuts.length > 0
        Layout.fillWidth: true
        spacing: Tokens.spaceSm

        Repeater {
          model: Settings.data.controlCenter.shortcuts.filter(id => CcShortcutRegistry.has(id))

          delegate: CcIconButton {
            required property string modelData
            readonly property bool isRecord: modelData === "Record"
            Layout.fillWidth: true
            symbol: CcShortcutRegistry.symbolFor(modelData)
            tooltip: isRecord && recorder.running ? "Stop recording" : CcShortcutRegistry.labelFor(modelData)
            tone: isRecord && recorder.running ? "error" : ""
            available: modelData === "Record" ? root.hasRecorder : modelData === "ColorPicker" ? root.hasColorPicker : true
            onTapped: root.runShortcut(modelData)
          }
        }
      }
    }

    // ======== Toggle tiles from Settings.data.controlCenter.toggles (CcToggleRegistry) ========
    CcCard {
      visible: Settings.data.controlCenter.toggles.length > 0

      GridLayout {
        Layout.fillWidth: true
        columns: 2
        uniformCellWidths: true
        rowSpacing: Tokens.spaceSm
        columnSpacing: Tokens.spaceSm

        Repeater {
          model: Settings.data.controlCenter.toggles

          delegate: Loader {
            id: toggleLoader
            required property string modelData
            required property int index
            // An odd last tile takes the whole row.
            readonly property int count: Settings.data.controlCenter.toggles.length
            Layout.columnSpan: toggleLoader.index === toggleLoader.count - 1 && toggleLoader.count % 2 === 1 ? 2 : 1
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            active: CcToggleRegistry.has(modelData)
            source: CcToggleRegistry.sourceFor(modelData)

            // The chevron on the Wi-Fi and Bluetooth tiles opens their sub-page.
            Connections {
              target: toggleLoader.item
              ignoreUnknownSignals: true
              function onExpandRequested(which) {
                root.page = which;
              }
            }
          }
        }
      }
    }

    // ======== Audio and brightness ========
    CcCard {
      spacing: Tokens.spaceMd

      RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spaceSm

        NSymbol {
          name: "headphones"
          size: 16
          color: Colors.primary
        }
        NText {
          text: "OUTPUT"
          tracking: true
          size: NText.Size.LabelXs
          font.weight: Font.DemiBold
          color: Colors.labelText
        }
        NText {
          Layout.fillWidth: true
          text: root.sink ? (root.sink.description || root.sink.name || "Output") : "No output"
          size: NText.Size.Caption
          color: Colors.surfaceTextMuted
        }
        NSymbol {
          name: "chevron_right"
          size: 18
          color: soundHover.hovered ? Colors.primary : Colors.surfaceTextMuted

          HoverHandler {
            id: soundHover
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: root.closeAndOpen("sound")
          }
        }
      }

      Repeater {
        model: [
          {
            "kind": "out"
          },
          {
            "kind": "in"
          },
          {
            "kind": "bri"
          }
        ]

        delegate: RowLayout {
          id: level
          required property var modelData
          readonly property bool isOut: modelData.kind === "out"
          readonly property bool isIn: modelData.kind === "in"
          readonly property bool isBri: modelData.kind === "bri"
          readonly property real pct: level.isOut ? (root.muted ? 0 : root.volume * 100) : level.isIn ? (root.source && root.source.audio && !root.micMuted ? root.source.audio.volume * 100 : 0) : root.brightnessPercent

          visible: !level.isBri || root.hasBacklight
          Layout.fillWidth: true
          spacing: Tokens.spaceMd

          CcIconButton {
            size: 32
            symbol: level.isBri ? "brightness_6" : level.isOut ? (root.muted ? "volume_off" : root.volume < 0.34 ? "volume_mute" : root.volume < 0.67 ? "volume_down" : "volume_up") : (root.micMuted ? "mic_off" : "mic")
            tooltip: level.isBri ? "" : (level.isOut ? (root.muted ? "Unmute" : "Mute") : (root.micMuted ? "Unmute microphone" : "Mute microphone"))
            tone: (level.isOut && root.muted) || (level.isIn && root.micMuted) ? "error" : ""
            available: level.isBri || (level.isOut ? !!root.sink : !!root.source)
            onTapped: {
              if (level.isOut && root.sink && root.sink.audio)
                root.sink.audio.muted = !root.sink.audio.muted;
              else if (level.isIn && root.source && root.source.audio)
                root.source.audio.muted = !root.source.audio.muted;
            }
          }

          CcLevelSlider {
            Layout.fillWidth: true
            value: level.pct
            interactive: level.isBri || (level.isOut ? !!root.sink : !!root.source)
            onMoved: pct => {
              if (level.isOut && root.sink && root.sink.audio) {
                root.sink.audio.volume = pct / 100;
                if (pct > 0)
                  root.sink.audio.muted = false;
              } else if (level.isIn && root.source && root.source.audio) {
                root.source.audio.volume = pct / 100;
                if (pct > 0)
                  root.source.audio.muted = false;
              } else if (level.isBri) {
                root.setBrightness(pct);
              }
            }
          }

          NText {
            Layout.preferredWidth: 40
            Layout.minimumWidth: 40
            Layout.maximumWidth: 40
            horizontalAlignment: Text.AlignRight
            text: Math.round(level.pct) + "%"
            size: NText.Size.Caption
            color: Colors.surfaceTextMuted
            font.features: {
              "tnum": 1
            }
          }
        }
      }
    }

    // ======== Media (only while a player exists) ========
    CcCard {
      visible: !!MediaService.activePlayer

      RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spaceLg

        Item {
          Layout.preferredWidth: 52
          Layout.preferredHeight: 52

          Rectangle {
            anchors.fill: parent
            color: Colors.surfaceContainerHigh
          }
          Image {
            id: cover
            anchors.fill: parent
            source: MediaService.activePlayer ? (MediaService.activePlayer.trackArtUrl || "") : ""
            sourceSize.width: 104
            sourceSize.height: 104
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
          }
          NSymbol {
            anchors.centerIn: parent
            visible: cover.status !== Image.Ready
            name: "music_note"
            size: 24
            color: Colors.labelText
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Tokens.spaceXs

          NText {
            Layout.fillWidth: true
            text: MediaService.activePlayer ? (MediaService.activePlayer.trackTitle || MediaService.activePlayer.identity) : ""
            size: NText.Size.BodySm
            font.weight: Font.DemiBold
          }
          NText {
            Layout.fillWidth: true
            text: MediaService.activePlayer ? (MediaService.activePlayer.trackArtist || MediaService.activePlayer.identity) : ""
            size: NText.Size.Caption
            color: Colors.labelText
          }
          CcLevelSlider {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spaceXs
            thumbRadius: 5
            trackHeight: 3
            value: MediaService.length > 0 ? (MediaService.position / MediaService.length) * 100 : 0
            interactive: !!MediaService.activePlayer && MediaService.activePlayer.canSeek
            onMoved: pct => {
              if (MediaService.activePlayer && MediaService.activePlayer.canSeek)
                MediaService.activePlayer.position = (pct / 100) * MediaService.length;
            }
          }
        }

        CcIconButton {
          size: 32
          symbol: "skip_previous"
          available: !!MediaService.activePlayer && MediaService.activePlayer.canGoPrevious
          onTapped: MediaService.activePlayer.previous()
        }
        CcIconButton {
          size: 36
          symbol: MediaService.isPlaying ? "pause" : "play_arrow"
          tone: "active"
          available: !!MediaService.activePlayer && (MediaService.activePlayer.canPlay || MediaService.activePlayer.canPause)
          onTapped: MediaService.activePlayer.togglePlaying()
        }
        CcIconButton {
          size: 32
          symbol: "skip_next"
          available: !!MediaService.activePlayer && MediaService.activePlayer.canGoNext
          onTapped: MediaService.activePlayer.next()
        }
      }
    }

    // ======== Weather and system stats ========
    RowLayout {
      Layout.fillWidth: true
      spacing: Tokens.spaceMd

      // Weather; a click opens the full forecast.
      CcCard {
        visible: Weather.ready && Settings.data.controlCenter.showWeather
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.fillHeight: true

        HoverHandler {
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: root.closeAndOpen("weather")
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Tokens.spaceMd

          NSymbol {
            name: root.weatherSymbol(Weather.currentWeatherCode, Weather.isDay)
            size: 40
            filled: true
            color: Colors.tertiary
          }
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            NText {
              text: Math.round(Weather.currentTempF) + "°"
              size: NText.Size.Title
            }
            NText {
              Layout.fillWidth: true
              text: Weather.description(Weather.currentWeatherCode)
              size: NText.Size.Caption
              color: Colors.surfaceTextMuted
            }
          }
        }
        RowLayout {
          Layout.fillWidth: true
          spacing: Tokens.spaceXs
          NSymbol {
            name: "water_drop"
            size: 13
            color: Colors.primary
          }
          NText {
            text: (Weather.daily.length > 0 ? Weather.daily[0].rain : 0) + "%"
            size: NText.Size.Caption
            color: Colors.labelText
          }
          NSymbol {
            Layout.leftMargin: Tokens.spaceSm
            name: "air"
            size: 13
            color: Colors.primary
          }
          NText {
            Layout.fillWidth: true
            text: Weather.windSpeed + " " + Weather.windUnit
            size: NText.Size.Caption
            color: Colors.labelText
          }
        }
        NText {
          Layout.fillWidth: true
          text: Weather.cityName.toUpperCase()
          tracking: true
          size: NText.Size.LabelXs
          color: Colors.labelText
        }
      }

      // Live stats; a click opens the full system stats.
      CcCard {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.fillHeight: true

        HoverHandler {
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: root.closeAndOpen("systemStats")
        }

        GridLayout {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignHCenter
          columns: 2
          rowSpacing: Tokens.spaceSm
          columnSpacing: Tokens.spaceSm

          CircularGauge {
            Layout.alignment: Qt.AlignHCenter
            percent: SystemStats.cpuPercent
            value: Math.round(SystemStats.cpuPercent) + "%"
            label: "CPU"
          }
          CircularGauge {
            Layout.alignment: Qt.AlignHCenter
            percent: Math.min(100, SystemStats.tempC)
            fillColor: Colors.tertiary
            value: Math.round(SystemStats.tempC) + "°"
            label: "TEMP"
          }
          CircularGauge {
            Layout.alignment: Qt.AlignHCenter
            percent: SystemStats.memPercent
            value: SystemStats.memUsedGb.toFixed(1) + "G"
            label: "MEM"
          }
          CircularGauge {
            Layout.alignment: Qt.AlignHCenter
            percent: SystemStats.rootDiskPercent
            value: Math.round(SystemStats.rootDiskPercent) + "%"
            label: "DISK"
          }
        }
      }
    }

    // ======== Homelab: hosts from Settings.data.homelab, pinged while open ========
    CcCard {
      visible: Homelab.hosts.length > 0
      spacing: Tokens.spaceSm

      RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spaceSm

        NSymbol {
          name: "dns"
          size: 16
          color: Colors.primary
        }
        NText {
          text: "HOMELAB"
          tracking: true
          size: NText.Size.LabelXs
          font.weight: Font.DemiBold
          color: Colors.labelText
        }
        NText {
          Layout.fillWidth: true
          text: Object.keys(Homelab.status).length === 0 ? "" : Homelab.upCount + "/" + Homelab.hosts.length + " up"
          size: NText.Size.Caption
          color: Homelab.upCount === Homelab.hosts.length ? Colors.primary : Colors.tertiary
        }
        NText {
          visible: Settings.data.homelab.dashboardUrl !== ""
          text: "DASHBOARD"
          tracking: true
          size: NText.Size.LabelXs
          font.weight: Font.DemiBold
          color: dashHover.hovered ? Colors.primary : Colors.labelText

          HoverHandler {
            id: dashHover
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: {
              root.requestClose();
              Qt.openUrlExternally(Settings.data.homelab.dashboardUrl);
            }
          }
        }
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 3
        uniformCellWidths: true
        rowSpacing: Tokens.spaceXs
        columnSpacing: Tokens.spaceXs

        Repeater {
          model: Homelab.hosts

          delegate: Item {
            id: hostCell
            required property var modelData
            readonly property var hostState: Homelab.status[modelData.name]
            readonly property bool known: !!hostCell.hostState
            readonly property bool up: hostCell.known && hostCell.hostState.up
            Layout.fillWidth: true
            implicitHeight: 30

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: Colors.surfaceContainerLow
              strokeColor: hostCell.known && !hostCell.up ? Colors.alpha(Colors.error, Tokens.destructiveBorderAlpha * 2) : Colors.outlineVariant
              strokeWidth: Tokens.borderModule
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Tokens.spaceMd
              anchors.rightMargin: Tokens.spaceMd
              spacing: Tokens.spaceSm

              // Status square: up, down, or not checked yet.
              Rectangle {
                Layout.preferredWidth: 6
                Layout.preferredHeight: 6
                color: !hostCell.known ? Colors.disabledText : hostCell.up ? Colors.primary : Colors.error
              }
              NText {
                Layout.fillWidth: true
                text: hostCell.modelData.name
                size: NText.Size.Caption
                color: hostCell.known && !hostCell.up ? Colors.error : Colors.surfaceText
              }
              NText {
                visible: hostCell.up && hostCell.hostState.ms >= 0
                text: hostCell.up ? (hostCell.hostState.ms < 1 ? "<1" : hostCell.hostState.ms) + "ms" : ""
                size: NText.Size.LabelXs
                color: Colors.labelText
              }
            }
          }
        }
      }
    }

    // ======== Recent notifications ========
    CcCard {
      spacing: Tokens.spaceSm

      RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spaceSm

        NSymbol {
          name: Settings.data.notifications.doNotDisturb ? "notifications_off" : "notifications"
          size: 16
          filled: Notifs.history.length > 0
          color: Colors.primary
        }
        NText {
          text: "NOTIFICATIONS"
          tracking: true
          size: NText.Size.LabelXs
          font.weight: Font.DemiBold
          color: Colors.labelText
        }
        NText {
          Layout.fillWidth: true
          text: Notifs.history.length > 0 ? String(Notifs.history.length) : ""
          size: NText.Size.Caption
          color: Colors.primary
        }
        NText {
          visible: Notifs.history.length > 0
          text: "CLEAR"
          tracking: true
          size: NText.Size.LabelXs
          font.weight: Font.DemiBold
          color: clearHover.hovered ? Colors.error : Colors.labelText

          HoverHandler {
            id: clearHover
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: Notifs.clearHistory()
          }
        }
        NText {
          Layout.leftMargin: Tokens.spaceMd
          text: "SEE ALL"
          tracking: true
          size: NText.Size.LabelXs
          font.weight: Font.DemiBold
          color: allHover.hovered ? Colors.primary : Colors.labelText

          HoverHandler {
            id: allHover
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: root.closeAndOpen("notificationHistory")
          }
        }
      }

      NText {
        visible: Notifs.history.length === 0
        Layout.fillWidth: true
        Layout.topMargin: Tokens.spaceSm
        Layout.bottomMargin: Tokens.spaceSm
        horizontalAlignment: Text.AlignHCenter
        text: "All caught up"
        size: NText.Size.Caption
        color: Colors.labelText
      }

      Repeater {
        model: Notifs.history.slice(0, 3)

        delegate: Item {
          id: note
          required property var modelData
          required property int index
          Layout.fillWidth: true
          implicitHeight: noteCol.implicitHeight + Tokens.spaceMd * 2

          PopupRowBackground {
            anchors.fill: parent
            hovered: false
          }

          Rectangle {
            visible: note.modelData.urgency === 2
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Tokens.borderMarker
            color: Colors.error
          }

          ColumnLayout {
            id: noteCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Tokens.spaceMd
            anchors.rightMargin: Tokens.spaceMd
            spacing: 0

            RowLayout {
              Layout.fillWidth: true
              NText {
                Layout.fillWidth: true
                text: (note.modelData.appName || "Notification").toUpperCase()
                tracking: true
                size: NText.Size.LabelXs
                color: Colors.labelText
              }
              NText {
                text: root.ago(note.modelData.timestamp + 0 * root.now)
                size: NText.Size.Caption
                color: Colors.labelText
              }
            }
            NText {
              Layout.fillWidth: true
              text: note.modelData.summary
              size: NText.Size.BodySm
              font.weight: Font.DemiBold
            }
            NText {
              Layout.fillWidth: true
              visible: text !== ""
              text: note.modelData.body.replace(/<[^>]*>/g, "").replace(/\n/g, " ")
              size: NText.Size.Caption
              color: Colors.surfaceTextMuted
            }
          }
        }
      }
    }
  }

  Item {
    id: subPage
    width: root.width
    // Keeps the last sub-page on screen while it slides away.
    property string shownPage: ""
    readonly property Item content: subPage.shownPage === "bluetooth" ? btPage : wifiPage
    implicitHeight: Math.min(subPage.content.implicitHeight, root.subPageMax)
    height: subPage.implicitHeight
    visible: opacity > 0
    opacity: root.page !== "" ? 1 : 0
    x: root.page !== "" ? 0 : Tokens.spaceXl * 2
    clip: true

    Connections {
      target: root
      function onPageChanged() {
        if (root.page !== "")
          subPage.shownPage = root.page;
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: Tokens.durationSidebarSlide
        easing.type: Tokens.easingSidebarSlide
      }
    }
    Behavior on x {
      NumberAnimation {
        duration: Tokens.durationSidebarSlide
        easing.type: Tokens.easingSidebarSlide
      }
    }

    WifiPanelContent {
      id: wifiPage
      anchors.fill: parent
      visible: subPage.shownPage === "wifi"
      panelActive: root.active && root.page === "wifi"
      showBack: true
      onBackRequested: root.page = ""
      onRequestClose: root.page = ""
    }
    BluetoothPanelContent {
      id: btPage
      anchors.fill: parent
      visible: subPage.shownPage === "bluetooth"
      panelActive: root.active && root.page === "bluetooth"
      showBack: true
      onBackRequested: root.page = ""
    }
  }
}
