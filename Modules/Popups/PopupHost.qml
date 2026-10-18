import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Modules.Popups.Contents

// One always-mapped overlay per screen hosting every bar popup as a SlideCard, so cards can animate closed.
// See docs/design-notes.md, "Always-mapped overlay windows need an explicit input mask".
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property string barPos: Settings.isLoaded ? Settings.getBarPositionForScreen(root.targetScreen ? root.targetScreen.name : "") : "top"

  readonly property var cards: [soundCard, batteryCard, bluetoothCard, wifiCard, hueCard, microphoneCard, brightnessCard, clipboardCard, claudeUsageCard, notificationHistoryCard, systemStatsCard, calendarCard, mediaPlayerCard, controlCenterCard]

  // An explicit OR chain: array indirection in a binding is what QML's dependency tracker has been unreliable about.
  readonly property bool anyOpen: soundCard.shown || batteryCard.shown || bluetoothCard.shown || wifiCard.shown || hueCard.shown || microphoneCard.shown || brightnessCard.shown || clipboardCard.shown || claudeUsageCard.shown || notificationHistoryCard.shown || systemStatsCard.shown || calendarCard.shown || mediaPlayerCard.shown || controlCenterCard.shown

  function closeAll(): void {
    for (const card of root.cards)
      card.close();
  }

  // Focus while open, and cleared on an outside click on any monitor; an Exclusive layer would swallow those clicks.
  HyprlandFocusGrab {
    active: root.anyOpen
    windows: [root]
    onCleared: Popups.closeAll()
  }

  // Lets bar widgets on this screen reach a card directly instead of round-tripping through qs ipc.
  Component.onCompleted: {
    for (const card of root.cards)
      Popups.register(card.popupName, root.targetScreen, card);
  }
  Component.onDestruction: {
    for (const card of root.cards)
      Popups.unregister(card.popupName, root.targetScreen);
  }

  visible: true
  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  // Click-through while closed; a mapped layer surface otherwise eats input across its whole geometry.
  mask: root.anyOpen ? null : emptyMask

  Region {
    id: emptyMask
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-popup-host"
  WlrLayershell.keyboardFocus: root.anyOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  Shortcut {
    sequence: "Escape"
    enabled: root.anyOpen
    onActivated: root.closeAll()
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.anyOpen
    onClicked: Popups.closeAll()
  }

  SlideCard {
    id: soundCard
    host: root
    barPos: root.barPos
    popupName: "sound"
    cardWidth: 300
    cardHeight: soundContent.implicitHeight + contentMargins * 2

    SoundPopupContent {
      id: soundContent
      anchors.fill: parent
    }
  }

  SlideCard {
    id: batteryCard
    host: root
    barPos: root.barPos
    popupName: "battery"
    cardWidth: 280
    cardHeight: batteryContent.implicitHeight + contentMargins * 2

    BatteryPopupContent {
      id: batteryContent
      anchors.fill: parent
    }
  }

  SlideCard {
    id: bluetoothCard
    host: root
    barPos: root.barPos
    popupName: "bluetooth"
    cardWidth: 320
    cardHeight: Math.min(480, bluetoothContent.implicitHeight + contentMargins * 2)

    BluetoothPanelContent {
      id: bluetoothContent
      anchors.fill: parent
      panelActive: bluetoothCard.shown
    }
  }

  SlideCard {
    id: wifiCard
    host: root
    barPos: root.barPos
    popupName: "wifi"
    cardWidth: 360
    cardHeight: Math.min(560, wifiContent.implicitHeight + contentMargins * 2)

    WifiPanelContent {
      id: wifiContent
      anchors.fill: parent
      panelActive: wifiCard.shown
    }
  }

  SlideCard {
    id: hueCard
    host: root
    barPos: root.barPos
    popupName: "hue"
    cardWidth: 300
    cardHeight: Math.min(320, hueContent.implicitHeight + contentMargins * 2)

    HuePanelContent {
      id: hueContent
      anchors.fill: parent
    }
  }

  SlideCard {
    id: microphoneCard
    host: root
    barPos: root.barPos
    popupName: "microphone"
    cardWidth: 300
    cardHeight: microphoneContent.implicitHeight + contentMargins * 2

    MicrophonePopupContent {
      id: microphoneContent
      anchors.fill: parent
    }
  }

  SlideCard {
    id: brightnessCard
    host: root
    barPos: root.barPos
    popupName: "brightness"
    cardWidth: 260
    cardHeight: brightnessContent.implicitHeight + contentMargins * 2

    BrightnessPopupContent {
      id: brightnessContent
      anchors.fill: parent
    }
  }

  SlideCard {
    id: clipboardCard
    host: root
    barPos: root.barPos
    popupName: "clipboard"
    cardWidth: 340
    cardHeight: Math.min(480, clipboardContent.implicitHeight + contentMargins * 2)

    ClipboardPopupContent {
      id: clipboardContent
      anchors.fill: parent
      active: clipboardCard.shown
      onRequestClose: clipboardCard.shown = false
    }
  }

  SlideCard {
    id: claudeUsageCard
    host: root
    barPos: root.barPos
    popupName: "claudeUsage"
    cardWidth: 300
    cardHeight: Math.min(400, claudeUsageContent.implicitHeight + contentMargins * 2)

    ClaudeUsagePopupContent {
      id: claudeUsageContent
      anchors.fill: parent
      active: claudeUsageCard.shown
    }
  }

  SlideCard {
    id: notificationHistoryCard
    host: root
    barPos: root.barPos
    popupName: "notificationHistory"
    cardWidth: 380
    cardHeight: Math.min(520, notificationHistoryContent.implicitHeight + contentMargins * 2)

    NotificationHistoryPopupContent {
      id: notificationHistoryContent
      anchors.fill: parent
      active: notificationHistoryCard.shown
    }
  }

  SlideCard {
    id: systemStatsCard
    host: root
    barPos: root.barPos
    popupName: "systemStats"
    cardWidth: 480
    cardHeight: systemStatsContent.implicitHeight + contentMargins * 2

    SystemStatsPopupContent {
      id: systemStatsContent
      anchors.fill: parent
      active: systemStatsCard.shown
    }
  }

  SlideCard {
    id: calendarCard
    host: root
    barPos: root.barPos
    popupName: "calendar"
    cardWidth: 308
    cardHeight: calendarContent.implicitHeight + contentMargins * 2
    // Reopening lands on the current month, not wherever paging left off.
    onShownChanged: if (shown)
      calendarContent.reset()

    CalendarPopupContent {
      id: calendarContent
      anchors.fill: parent
    }
  }

  SlideCard {
    id: mediaPlayerCard
    host: root
    barPos: root.barPos
    popupName: "mediaPlayer"
    cardWidth: 396
    cardHeight: mediaPlayerContent.implicitHeight + contentMargins * 2

    MediaPlayerPopupContent {
      id: mediaPlayerContent
      anchors.fill: parent
    }
  }

  SlideCard {
    id: controlCenterCard
    host: root
    barPos: root.barPos
    popupName: "controlCenter"
    alwaysMorph: true
    cardWidth: 436
    cardHeight: controlCenterContent.implicitHeight + contentMargins * 2

    ControlCenterPopupContent {
      id: controlCenterContent
      anchors.fill: parent
      active: controlCenterCard.shown
      targetScreen: root.targetScreen
      onRequestClose: controlCenterCard.close()
    }
  }

  PopupIpc {
    host: root
    card: soundCard
  }
  PopupIpc {
    host: root
    card: batteryCard
  }
  PopupIpc {
    host: root
    card: bluetoothCard
  }
  PopupIpc {
    host: root
    card: wifiCard
  }
  PopupIpc {
    host: root
    card: hueCard
  }
  PopupIpc {
    host: root
    card: microphoneCard
  }
  PopupIpc {
    host: root
    card: brightnessCard
  }
  PopupIpc {
    host: root
    card: clipboardCard
  }
  PopupIpc {
    host: root
    card: claudeUsageCard
  }
  PopupIpc {
    host: root
    card: notificationHistoryCard
  }
  PopupIpc {
    host: root
    card: systemStatsCard
  }
  PopupIpc {
    host: root
    card: calendarCard
  }
  PopupIpc {
    host: root
    card: mediaPlayerCard
  }
  PopupIpc {
    host: root
    card: controlCenterCard
  }
}
