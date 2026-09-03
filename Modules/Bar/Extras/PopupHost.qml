import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

// One always-mapped overlay per screen, hosting every bar popup as a
// SlideCard-wrapped child instead of each popup being its own
// PanelWindow. Staying mapped (never visible:false) is what lets a popup
// actually slide back out on close, not just vanish — an unmapped
// layer-shell surface can't render a closing animation. See crux skill's
// notes.md for the fuller rationale and what this replaced.
//
// Each card declares its own size and content; the shared open/close/
// position behaviour lives in SlideCard and PopupIpc, so adding a popup
// means one SlideCard plus one PopupIpc line, not a fresh copy of both.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property string barPos: Settings.isLoaded ? Settings.getBarPositionForScreen(root.targetScreen ? root.targetScreen.name : "") : "top"

  readonly property var cards: [soundCard, batteryCard, bluetoothCard, wifiCard, hueCard, microphoneCard, brightnessCard, clipboardCard, claudeUsageCard, notificationHistoryCard, systemStatsCard]

  // Deliberately an explicit OR chain rather than cards.some(...): this
  // drives the input mask, and a binding that reads each card through an
  // array indirection is exactly the shape QML's dependency tracker has
  // been unreliable about here (see the crux skill's Grid/itemAt gotcha).
  readonly property bool anyOpen: soundCard.open || batteryCard.open || bluetoothCard.open || wifiCard.open || hueCard.open || microphoneCard.open || brightnessCard.open || clipboardCard.open || claudeUsageCard.open || notificationHistoryCard.open || systemStatsCard.open

  function closeAll(): void {
    for (const card of root.cards)
      card.open = false;
  }

  // Lets a bar widget on this screen reach a card directly instead of
  // forking `qs ipc` back into this same process.
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
      panelActive: bluetoothCard.open
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
      panelActive: wifiCard.open
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
      active: clipboardCard.open
      onRequestClose: clipboardCard.open = false
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
      active: claudeUsageCard.open
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
      active: notificationHistoryCard.open
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
      active: systemStatsCard.open
      onRequestClose: systemStatsCard.open = false
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
}
