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

  readonly property bool anyOpen: soundCard.open

  function closeAll() {
    soundCard.open = false;
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
    cardHeight: soundContent.implicitHeight + 24

    SoundPopupContent {
      id: soundContent
      anchors.fill: parent
      anchors.margins: 14
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
}
