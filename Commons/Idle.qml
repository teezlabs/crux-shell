pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

// Real idle-timeout backend — ext-idle-notify-v1 via Quickshell.Wayland's
// IdleMonitor, the same native Wayland protocol swayidle/hypridle use, not a
// generated hypridle.conf + external process (crux has no idle infra at
// all yet, and this box has hypridle installed but never configured).
// Ported down from noctalia-shell's Services/Power/IdleService.qml (crux
// skill: "port the real logic, adapt the UI shell") — trimmed of its
// CompositorService abstraction (crux only targets Hyprland directly) and
// its fade-to-black overlay (out of scope for this pass; each stage still
// waits Settings.data.idle.fadeDurationSec before firing, cancellable by
// any activity, just without the visual fade).
//
// Three built-in stages (screenOff/lock/suspend) plus arbitrary user-defined
// custom commands, each backed by its own dynamically-created IdleMonitor
// (Qt.createQmlObject, same as noctalia — IdleMonitor throws on a compositor
// without the protocol, so every creation is wrapped in try/catch).
Singleton {
  id: root

  readonly property bool nativeIdleMonitorAvailable: _monitorsCreated
  property bool _monitorsCreated: false

  property var _screenOffMonitor: null
  property var _lockMonitor: null
  property var _suspendMonitor: null
  property var _customMonitors: ({})

  // "" when idle, else whichever built-in stage is mid-grace-period.
  property string pendingStage: ""

  function init() {
    _applyTimeouts();
  }

  Timer {
    id: graceTimer
    interval: Math.max(1, Settings.data.idle.fadeDurationSec) * 1000
    repeat: false
    onTriggered: root._executeAction(root.pendingStage)
  }

  function _isValidStage(stage) {
    return stage === "screenOff" || stage === "lock" || stage === "suspend";
  }

  function _isStageEnabled(stage) {
    var idle = Settings.data.idle;
    if (stage === "screenOff")
      return idle.screenOffTimeoutSec > 0;
    if (stage === "lock")
      return idle.lockTimeoutSec > 0;
    if (stage === "suspend")
      return idle.suspendTimeoutSec > 0;
    return false;
  }

  function _onIdle(stage) {
    if (!_isValidStage(stage) || !_isStageEnabled(stage))
      return;
    root.pendingStage = stage;
    graceTimer.restart();
  }

  // Any monitor going non-idle (real activity) cancels a pending fire and
  // runs that stage's own resume command, if any.
  function _onActive(stage) {
    if (root.pendingStage === stage) {
      graceTimer.stop();
      root.pendingStage = "";
      return;
    }
    var idle = Settings.data.idle;
    if (stage === "screenOff") {
      Quickshell.execDetached(["sh", "-c", idle.resumeScreenOffCommand || "hyprctl dispatch dpms on"]);
    } else if (stage === "suspend" && idle.resumeSuspendCommand) {
      Quickshell.execDetached(["sh", "-c", idle.resumeSuspendCommand]);
    }
  }

  function _executeAction(stage) {
    root.pendingStage = "";
    var idle = Settings.data.idle;
    if (stage === "screenOff") {
      Quickshell.execDetached(["sh", "-c", idle.screenOffCommand || "hyprctl dispatch dpms off"]);
    } else if (stage === "lock") {
      Quickshell.execDetached(["sh", "-c", idle.lockCommand || "qs ipc -c crux call lockscreen lock"]);
    } else if (stage === "suspend") {
      Quickshell.execDetached(["sh", "-c", idle.suspendCommand || "systemctl suspend || loginctl suspend"]);
    }
  }

  Connections {
    target: Settings
    function onSettingsLoaded() {
      root._applyTimeouts();
    }
  }

  Connections {
    target: Settings.data.idle
    function onEnabledChanged() {
      root._applyTimeouts();
    }
    function onScreenOffTimeoutSecChanged() {
      root._applyTimeouts();
    }
    function onLockTimeoutSecChanged() {
      root._applyTimeouts();
    }
    function onSuspendTimeoutSecChanged() {
      root._applyTimeouts();
    }
    function onCustomCommandsChanged() {
      root._applyCustomMonitors();
    }
  }

  function _applyTimeouts() {
    var idle = Settings.data.idle;
    var enabled = idle.enabled;
    _setMonitor("screenOff", "_screenOffMonitor", enabled ? idle.screenOffTimeoutSec : 0);
    _setMonitor("lock", "_lockMonitor", enabled ? idle.lockTimeoutSec : 0);
    _setMonitor("suspend", "_suspendMonitor", enabled ? idle.suspendTimeoutSec : 0);
    _applyCustomMonitors();
  }

  function _setMonitor(stage, propName, timeoutSec) {
    var existing = root[propName];
    if (timeoutSec <= 0) {
      if (existing) {
        existing.destroy();
        root[propName] = null;
      }
      return;
    }
    if (existing) {
      if (existing.timeout === timeoutSec)
        return;
      existing.destroy();
      root[propName] = null;
    }
    try {
      var qml = "import Quickshell.Wayland\nIdleMonitor { timeout: " + timeoutSec + " }";
      var monitor = Qt.createQmlObject(qml, root, "IdleMonitor_" + stage);
      monitor.isIdleChanged.connect(function () {
        if (monitor.isIdle)
          root._onIdle(stage);
        else
          root._onActive(stage);
      });
      root[propName] = monitor;
      root._monitorsCreated = true;
    } catch (e) {
      root._monitorsCreated = false;
    }
  }

  function _applyCustomMonitors() {
    for (var key in root._customMonitors) {
      if (root._customMonitors[key])
        root._customMonitors[key].destroy();
    }
    root._customMonitors = ({});

    var idle = Settings.data.idle;
    if (!idle.enabled)
      return;

    var entries = [];
    try {
      entries = JSON.parse(idle.customCommands);
    } catch (e) {
      return;
    }

    var next = ({});
    for (var i = 0; i < entries.length; i++) {
      var entry = entries[i];
      var timeoutSec = parseInt(entry.timeout);
      var cmd = entry.command || "";
      var resumeCmd = entry.resumeCommand || "";
      if (timeoutSec <= 0 || (!cmd && !resumeCmd))
        continue;
      try {
        var qml2 = "import Quickshell.Wayland\nIdleMonitor { timeout: " + timeoutSec + " }";
        var monitor = Qt.createQmlObject(qml2, root, "IdleMonitor_custom_" + i);
        (function (capturedCmd, capturedResumeCmd) {
          monitor.isIdleChanged.connect(function () {
            if (monitor.isIdle) {
              if (capturedCmd)
                Quickshell.execDetached(["sh", "-c", capturedCmd]);
            } else if (capturedResumeCmd) {
              Quickshell.execDetached(["sh", "-c", capturedResumeCmd]);
            }
          });
        })(cmd, resumeCmd);
        next[i] = monitor;
        root._monitorsCreated = true;
      } catch (e) {
        // Compositor lacks ext-idle-notify-v1 — leave _monitorsCreated as-is.
      }
    }
    root._customMonitors = next;
  }
}
