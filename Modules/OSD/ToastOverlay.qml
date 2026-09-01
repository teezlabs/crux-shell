import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Modules.Bar.Extras

// Toast overlay: renders Commons/Toast.qml's queued messages as a small
// chamfered pill, bottom-center of the primary screen. One global instance
// (see shell.qml) rather than per-screen like VolumeOsd.qml/
// NotificationsWindow.qml — a toast ("Theme updated", "Wallpaper applied")
// isn't tied to any one monitor's audio/notification state, so a single
// shared surface is simpler and reads just as correctly.
//
// Structurally this is VolumeOsd.qml's own "transient, auto-hiding, no user
// interaction" pattern (opened flag + Timer + click-through mask), plus a
// small FIFO queue on top so back-to-back Toast.show() calls (e.g. cycling
// through wallpaper accents quickly) each get their own brief pill instead
// of clobbering one another mid-fade.
PanelWindow {
  id: root

  screen: Quickshell.screens[0] ?? null

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

  // Small gap after a toast finishes fading out before the next queued
  // one starts fading in — avoids two toasts visually overlapping.
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

    // Opposite diagonal from VolumeOsd/NotificationsWindow's
    // top-right+bottom-left chamfer — keeps the same chamfer language
    // but reads as a visually distinct, lighter-weight surface rather
    // than a clone of either.
    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferModule
      cutTopLeft: true
      cutBottomRight: true
      fillColor: Color.alpha(Color.surfaceContainerHigh, Tokens.panelOpacity)
      strokeColor: Color.outlineVariant
      strokeWidth: Tokens.borderModule
    }

    Text {
      id: label
      anchors.centerIn: parent
      text: root.message
      color: Color.surfaceText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.bodySmSize
      font.weight: Font.DemiBold
    }
  }
}
