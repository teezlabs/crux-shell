import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons

// One always-mapped overlay per screen, hosting every bar popup as a
// SlideCard-wrapped child instead of each popup being its own
// PanelWindow. Staying mapped (never visible:false) is what lets a popup
// actually slide back out on close, not just vanish — an unmapped
// layer-shell surface can't render a closing animation. See crux skill's
// notes.md for the fuller rationale and what this replaced.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property string barPos: Settings.isLoaded ? Settings.getBarPositionForScreen(root.targetScreen ? root.targetScreen.name : "") : "top"

  readonly property bool anyOpen: soundCard.open || batteryCard.open || bluetoothCard.open || wifiCard.open || hueCard.open || microphoneCard.open || brightnessCard.open || clipboardCard.open || claudeUsageCard.open || notificationHistoryCard.open || systemStatsCard.open

  function closeAll() {
    soundCard.open = false;
    batteryCard.open = false;
    bluetoothCard.open = false;
    wifiCard.open = false;
    hueCard.open = false;
    microphoneCard.open = false;
    brightnessCard.open = false;
    clipboardCard.open = false;
    claudeUsageCard.open = false;
    notificationHistoryCard.open = false;
    systemStatsCard.open = false;
  }

  visible: true
  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  // A mapped layer-shell surface claims input across its *entire*
  // geometry by default, regardless of any internal MouseArea's own
  // enabled binding — confirmed live: without this mask, staying mapped
  // to allow the slide-closed animation meant this surface silently
  // swallowed every click on the whole desktop even while fully closed
  // and invisible, a total input lockup, not just a stray click near the
  // card. `null` reverts to that same default (full capture) — used here
  // only while something's actually open, to catch an outside click and
  // close it, matching what the old per-popup PanelWindow's own
  // full-surface MouseArea did while visible. A genuinely empty Region
  // (not just a zero-sized one) is what actually gets fully click-through
  // — same idiom noctalia's own always-mapped overlays use.
  mask: root.anyOpen ? null : emptyMask

  Region {
    id: emptyMask
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-popup-host"
  WlrLayershell.keyboardFocus: root.anyOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  Shortcut {
    sequence: "Escape"
    enabled: root.anyOpen
    onActivated: root.closeAll()
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.anyOpen
    onClicked: root.closeAll()
  }

  SlideCard {
    id: soundCard
    host: root
    barPos: root.barPos
    cardWidth: 300
    cardHeight: soundContent.implicitHeight + 28

    SoundPopupContent {
      id: soundContent
      anchors.fill: parent
      anchors.margins: 14
    }
  }

  SlideCard {
    id: batteryCard
    host: root
    barPos: root.barPos
    cardWidth: 280
    cardHeight: batteryContent.implicitHeight + 28

    BatteryPopupContent {
      id: batteryContent
      anchors.fill: parent
      anchors.margins: 14
    }
  }

  SlideCard {
    id: bluetoothCard
    host: root
    barPos: root.barPos
    cardWidth: 320
    cardHeight: Math.min(480, bluetoothContent.implicitHeight + 28)

    BluetoothPanelContent {
      id: bluetoothContent
      anchors.fill: parent
      anchors.margins: 14
      panelActive: bluetoothCard.open
    }
  }

  SlideCard {
    id: wifiCard
    host: root
    barPos: root.barPos
    cardWidth: 360
    cardHeight: Math.min(560, wifiContent.implicitHeight + 28)

    WifiPanelContent {
      id: wifiContent
      anchors.fill: parent
      anchors.margins: 14
      panelActive: wifiCard.open
    }
  }

  SlideCard {
    id: hueCard
    host: root
    barPos: root.barPos
    cardWidth: 300
    cardHeight: Math.min(320, hueContent.implicitHeight + 28)

    HuePanelContent {
      id: hueContent
      anchors.fill: parent
      anchors.margins: 14
    }
  }

  SlideCard {
    id: microphoneCard
    host: root
    barPos: root.barPos
    cardWidth: 300
    cardHeight: microphoneContent.implicitHeight + 28

    MicrophonePopupContent {
      id: microphoneContent
      anchors.fill: parent
      anchors.margins: 14
    }
  }

  SlideCard {
    id: brightnessCard
    host: root
    barPos: root.barPos
    cardWidth: 260
    cardHeight: brightnessContent.implicitHeight + 28

    BrightnessPopupContent {
      id: brightnessContent
      anchors.fill: parent
      anchors.margins: 14
    }
  }

  SlideCard {
    id: clipboardCard
    host: root
    barPos: root.barPos
    cardWidth: 340
    cardHeight: Math.min(480, clipboardContent.implicitHeight + 28)

    ClipboardPopupContent {
      id: clipboardContent
      anchors.fill: parent
      anchors.margins: 14
      active: clipboardCard.open
      onRequestClose: clipboardCard.open = false
    }
  }

  SlideCard {
    id: claudeUsageCard
    host: root
    barPos: root.barPos
    cardWidth: 300
    cardHeight: Math.min(400, claudeUsageContent.implicitHeight + 28)

    ClaudeUsagePopupContent {
      id: claudeUsageContent
      anchors.fill: parent
      anchors.margins: 14
      active: claudeUsageCard.open
    }
  }

  SlideCard {
    id: notificationHistoryCard
    host: root
    barPos: root.barPos
    cardWidth: 380
    cardHeight: Math.min(520, notificationHistoryContent.implicitHeight + 28)

    NotificationHistoryPopupContent {
      id: notificationHistoryContent
      anchors.fill: parent
      anchors.margins: 14
      active: notificationHistoryCard.open
    }
  }

  SlideCard {
    id: systemStatsCard
    host: root
    barPos: root.barPos
    cardWidth: 480
    cardHeight: systemStatsContent.implicitHeight + 28

    SystemStatsPopupContent {
      id: systemStatsContent
      anchors.fill: parent
      anchors.margins: 14
      active: systemStatsCard.open
      onRequestClose: systemStatsCard.open = false
    }
  }

  // Per-screen target so a bar-icon click (which already knows its own
  // screen and the icon's position) opens flush with the right instance,
  // lined up with the icon — same pattern ControlCenterWindow.qml uses.
  IpcHandler {
    target: "sound_" + (root.targetScreen ? root.targetScreen.name : "0")
    function toggle() {
      soundCard.open = !soundCard.open;
    }
    function open() {
      soundCard.open = true;
    }
    function openAt(x: real, y: real) {
      if (soundCard.open) {
        soundCard.open = false;
        return;
      }
      if (root.barPos === "left" || root.barPos === "right")
        soundCard.crossPos = Math.max(8, Math.min(y, root.height - soundCard.cardHeight - 8));
      else
        soundCard.crossPos = Math.max(8, Math.min(x, root.width - soundCard.cardWidth - 8));
      soundCard.open = true;
    }
    function close() {
      soundCard.open = false;
    }
  }

  // Plain "sound" alias, claimed only by the instance on the
  // currently-focused monitor, for a keybind that doesn't know/care which
  // screen it's on.
  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "sound"
    function toggle() {
      soundCard.open = !soundCard.open;
    }
    function open() {
      soundCard.open = true;
    }
    function close() {
      soundCard.open = false;
    }
  }

  IpcHandler {
    target: "battery_" + (root.targetScreen ? root.targetScreen.name : "0")
    function toggle() {
      batteryCard.open = !batteryCard.open;
    }
    function open() {
      batteryCard.open = true;
    }
    function openAt(x: real, y: real) {
      if (batteryCard.open) {
        batteryCard.open = false;
        return;
      }
      if (root.barPos === "left" || root.barPos === "right")
        batteryCard.crossPos = Math.max(8, Math.min(y, root.height - batteryCard.cardHeight - 8));
      else
        batteryCard.crossPos = Math.max(8, Math.min(x, root.width - batteryCard.cardWidth - 8));
      batteryCard.open = true;
    }
    function close() {
      batteryCard.open = false;
    }
  }
  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "battery"
    function toggle() {
      batteryCard.open = !batteryCard.open;
    }
    function open() {
      batteryCard.open = true;
    }
    function close() {
      batteryCard.open = false;
    }
  }

  IpcHandler {
    target: "bluetooth_" + (root.targetScreen ? root.targetScreen.name : "0")
    function toggle() {
      bluetoothCard.open = !bluetoothCard.open;
    }
    function open() {
      bluetoothCard.open = true;
    }
    function openAt(x: real, y: real) {
      if (bluetoothCard.open) {
        bluetoothCard.open = false;
        return;
      }
      if (root.barPos === "left" || root.barPos === "right")
        bluetoothCard.crossPos = Math.max(8, Math.min(y, root.height - bluetoothCard.cardHeight - 8));
      else
        bluetoothCard.crossPos = Math.max(8, Math.min(x, root.width - bluetoothCard.cardWidth - 8));
      bluetoothCard.open = true;
    }
    function close() {
      bluetoothCard.open = false;
    }
  }
  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "bluetooth"
    function toggle() {
      bluetoothCard.open = !bluetoothCard.open;
    }
    function open() {
      bluetoothCard.open = true;
    }
    function close() {
      bluetoothCard.open = false;
    }
  }

  IpcHandler {
    target: "wifi_" + (root.targetScreen ? root.targetScreen.name : "0")
    function toggle() {
      wifiCard.open = !wifiCard.open;
    }
    function open() {
      wifiCard.open = true;
    }
    function openAt(x: real, y: real) {
      if (wifiCard.open) {
        wifiCard.open = false;
        return;
      }
      if (root.barPos === "left" || root.barPos === "right")
        wifiCard.crossPos = Math.max(8, Math.min(y, root.height - wifiCard.cardHeight - 8));
      else
        wifiCard.crossPos = Math.max(8, Math.min(x, root.width - wifiCard.cardWidth - 8));
      wifiCard.open = true;
    }
    function close() {
      wifiCard.open = false;
    }
  }
  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "wifi"
    function toggle() {
      wifiCard.open = !wifiCard.open;
    }
    function open() {
      wifiCard.open = true;
    }
    function close() {
      wifiCard.open = false;
    }
  }

  IpcHandler {
    target: "hue_" + (root.targetScreen ? root.targetScreen.name : "0")
    function toggle() {
      hueCard.open = !hueCard.open;
    }
    function open() {
      hueCard.open = true;
    }
    function openAt(x: real, y: real) {
      if (hueCard.open) {
        hueCard.open = false;
        return;
      }
      if (root.barPos === "left" || root.barPos === "right")
        hueCard.crossPos = Math.max(8, Math.min(y, root.height - hueCard.cardHeight - 8));
      else
        hueCard.crossPos = Math.max(8, Math.min(x, root.width - hueCard.cardWidth - 8));
      hueCard.open = true;
    }
    function close() {
      hueCard.open = false;
    }
  }
  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "hue"
    function toggle() {
      hueCard.open = !hueCard.open;
    }
    function open() {
      hueCard.open = true;
    }
    function close() {
      hueCard.open = false;
    }
  }
  IpcHandler {
    target: "microphone_" + (root.targetScreen ? root.targetScreen.name : "0")
    function toggle() {
      microphoneCard.open = !microphoneCard.open;
    }
    function open() {
      microphoneCard.open = true;
    }
    function openAt(x: real, y: real) {
      if (microphoneCard.open) {
        microphoneCard.open = false;
        return;
      }
      if (root.barPos === "left" || root.barPos === "right")
        microphoneCard.crossPos = Math.max(8, Math.min(y, root.height - microphoneCard.cardHeight - 8));
      else
        microphoneCard.crossPos = Math.max(8, Math.min(x, root.width - microphoneCard.cardWidth - 8));
      microphoneCard.open = true;
    }
    function close() {
      microphoneCard.open = false;
    }
  }
  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "microphone"
    function toggle() {
      microphoneCard.open = !microphoneCard.open;
    }
    function open() {
      microphoneCard.open = true;
    }
    function close() {
      microphoneCard.open = false;
    }
  }

  IpcHandler {
    target: "brightness_" + (root.targetScreen ? root.targetScreen.name : "0")
    function toggle() {
      brightnessCard.open = !brightnessCard.open;
    }
    function open() {
      brightnessCard.open = true;
    }
    function openAt(x: real, y: real) {
      if (brightnessCard.open) {
        brightnessCard.open = false;
        return;
      }
      if (root.barPos === "left" || root.barPos === "right")
        brightnessCard.crossPos = Math.max(8, Math.min(y, root.height - brightnessCard.cardHeight - 8));
      else
        brightnessCard.crossPos = Math.max(8, Math.min(x, root.width - brightnessCard.cardWidth - 8));
      brightnessCard.open = true;
    }
    function close() {
      brightnessCard.open = false;
    }
  }
  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "brightness"
    function toggle() {
      brightnessCard.open = !brightnessCard.open;
    }
    function open() {
      brightnessCard.open = true;
    }
    function close() {
      brightnessCard.open = false;
    }
  }

  IpcHandler {
    target: "clipboard_" + (root.targetScreen ? root.targetScreen.name : "0")
    function toggle() {
      clipboardCard.open = !clipboardCard.open;
    }
    function open() {
      clipboardCard.open = true;
    }
    function openAt(x: real, y: real) {
      if (clipboardCard.open) {
        clipboardCard.open = false;
        return;
      }
      if (root.barPos === "left" || root.barPos === "right")
        clipboardCard.crossPos = Math.max(8, Math.min(y, root.height - clipboardCard.cardHeight - 8));
      else
        clipboardCard.crossPos = Math.max(8, Math.min(x, root.width - clipboardCard.cardWidth - 8));
      clipboardCard.open = true;
    }
    function close() {
      clipboardCard.open = false;
    }
  }
  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "clipboard"
    function toggle() {
      clipboardCard.open = !clipboardCard.open;
    }
    function open() {
      clipboardCard.open = true;
    }
    function close() {
      clipboardCard.open = false;
    }
  }

  IpcHandler {
    target: "claudeUsage_" + (root.targetScreen ? root.targetScreen.name : "0")
    function toggle() {
      claudeUsageCard.open = !claudeUsageCard.open;
    }
    function open() {
      claudeUsageCard.open = true;
    }
    function openAt(x: real, y: real) {
      if (claudeUsageCard.open) {
        claudeUsageCard.open = false;
        return;
      }
      if (root.barPos === "left" || root.barPos === "right")
        claudeUsageCard.crossPos = Math.max(8, Math.min(y, root.height - claudeUsageCard.cardHeight - 8));
      else
        claudeUsageCard.crossPos = Math.max(8, Math.min(x, root.width - claudeUsageCard.cardWidth - 8));
      claudeUsageCard.open = true;
    }
    function close() {
      claudeUsageCard.open = false;
    }
  }
  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "claudeUsage"
    function toggle() {
      claudeUsageCard.open = !claudeUsageCard.open;
    }
    function open() {
      claudeUsageCard.open = true;
    }
    function close() {
      claudeUsageCard.open = false;
    }
  }

  IpcHandler {
    target: "notificationHistory_" + (root.targetScreen ? root.targetScreen.name : "0")
    function toggle() {
      notificationHistoryCard.open = !notificationHistoryCard.open;
    }
    function open() {
      notificationHistoryCard.open = true;
    }
    function openAt(x: real, y: real) {
      if (notificationHistoryCard.open) {
        notificationHistoryCard.open = false;
        return;
      }
      if (root.barPos === "left" || root.barPos === "right")
        notificationHistoryCard.crossPos = Math.max(8, Math.min(y, root.height - notificationHistoryCard.cardHeight - 8));
      else
        notificationHistoryCard.crossPos = Math.max(8, Math.min(x, root.width - notificationHistoryCard.cardWidth - 8));
      notificationHistoryCard.open = true;
    }
    function close() {
      notificationHistoryCard.open = false;
    }
  }
  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "notificationHistory"
    function toggle() {
      notificationHistoryCard.open = !notificationHistoryCard.open;
    }
    function open() {
      notificationHistoryCard.open = true;
    }
    function close() {
      notificationHistoryCard.open = false;
    }
  }

  IpcHandler {
    target: "systemStats_" + (root.targetScreen ? root.targetScreen.name : "0")
    function toggle() {
      systemStatsCard.open = !systemStatsCard.open;
    }
    function open() {
      systemStatsCard.open = true;
    }
    function openAt(x: real, y: real) {
      if (systemStatsCard.open) {
        systemStatsCard.open = false;
        return;
      }
      if (root.barPos === "left" || root.barPos === "right")
        systemStatsCard.crossPos = Math.max(8, Math.min(y, root.height - systemStatsCard.cardHeight - 8));
      else
        systemStatsCard.crossPos = Math.max(8, Math.min(x, root.width - systemStatsCard.cardWidth - 8));
      systemStatsCard.open = true;
    }
    function close() {
      systemStatsCard.open = false;
    }
  }
  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "systemStats"
    function toggle() {
      systemStatsCard.open = !systemStatsCard.open;
    }
    function open() {
      systemStatsCard.open = true;
    }
    function close() {
      systemStatsCard.open = false;
    }
  }

}
