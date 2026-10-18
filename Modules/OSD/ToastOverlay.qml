import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Modules.Notifications
import qs.Widgets

// Renders Toast's FIFO queue as a pill at the bottom centre of the focused monitor. One global instance.
PanelWindow {
  id: root

  screen: Quickshell.screens[0] ?? null

  function _focusedScreen() {
    const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
    for (const s of Quickshell.screens)
      if (s.name === name)
        return s;
    return Quickshell.screens[0] ?? null;
  }

  property var _queue: []
  property string message: ""
  property bool opened: false

  Connections {
    target: Toast
    function onRequested(msg, durationMs) {
      root._queue.push({
        "message": msg,
        "duration": durationMs
      });
      root._processQueue();
    }
  }

  function _processQueue() {
    if (root.opened || root._queue.length === 0)
      return;
    var next = root._queue.shift();
    // The window is unmapped between toasts, so it can move to the focused monitor first.
    root.screen = root._focusedScreen();
    root.message = next.message;
    root.opened = true;
    hideTimer.interval = next.duration;
    hideTimer.restart();
  }

  // Fires when the current toast's on-screen time is up.
  Timer {
    id: hideTimer
    repeat: false
    onTriggered: root.opened = false
  }

  // Short gap between toasts so they never overlap.
  Timer {
    id: nextTimer
    interval: Tokens.durationOsdFade + 40
    repeat: false
    onTriggered: root._processQueue()
  }

  onOpenedChanged: {
    if (!opened)
      nextTimer.restart();
  }

  visible: opened
  color: "transparent"

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  WlrLayershell.namespace: "crux-toast"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  // Visual only — never intercepts clicks meant for whatever's underneath.
  mask: Region {}

  Item {
    id: card
    width: Math.min(480, label.implicitWidth + 40)
    height: 36
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 60
    opacity: root.opened ? 1 : 0
    scale: root.opened ? 1 : 0.92

    Behavior on opacity {
      NumberAnimation {
        duration: Tokens.durationOsdFade
        easing.type: Tokens.easingOsdFade
      }
    }
    Behavior on scale {
      NumberAnimation {
        duration: Tokens.durationOsdFade
        easing.type: Tokens.easingOsdFade
      }
    }

    // Opposite diagonal to the OSD and notifications, so a toast reads as a lighter surface.
    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferModule
      cutTopLeft: true
      cutBottomRight: true
      fillColor: Colors.alpha(Colors.surfaceContainerHigh, Tokens.panelOpacity)
      strokeColor: Colors.outlineVariant
      strokeWidth: Tokens.borderModule
    }

    NText {
      id: label
      anchors.centerIn: parent
      text: root.message
      color: Colors.surfaceText
      size: NText.Size.BodySm
      font.weight: Font.DemiBold
    }
  }
}
