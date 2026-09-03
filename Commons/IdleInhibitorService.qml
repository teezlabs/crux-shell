pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Single source of truth for "keep this machine awake".
//
// There used to be two unrelated implementations: the Control Center tile
// drove a Wayland IdleInhibitor off Settings.data.general.keepAwake, while
// the KeepAwake bar widget ran its own systemd-inhibit subprocess against a
// local bool. Toggling one left the other showing the opposite state, and
// both could be on at once.
//
// State lives in Settings so it survives a restart and both surfaces agree.
// Two layers back it, because they stop different things:
//   - the compositor's idle notifications (ext-idle-notify-v1), which is
//     what Commons/Idle.qml listens to — inhibited by the IdleInhibitor
//     that ControlCenterWindow binds to `active`, since that one needs a
//     window to attach to;
//   - logind's own idle/sleep handling, via systemd-inhibit here.
// Idle.qml additionally refuses to fire a stage while this is on, rather
// than trusting the compositor to withhold the notification.
Singleton {
  id: root

  readonly property bool active: Settings.isLoaded ? Settings.data.general.keepAwake : false

  function setActive(on): void {
    if (Settings.isLoaded)
      Settings.data.general.keepAwake = on;
  }

  function toggle(): void {
    root.setActive(!root.active);
  }

  readonly property Process inhibitor: Process {
    running: root.active
    command: ["systemd-inhibit", "--what=idle:sleep", "--why=crux: keep awake", "--mode=block", "sleep", "infinity"]
  }
}
