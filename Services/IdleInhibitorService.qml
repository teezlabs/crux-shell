pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Single owner of keep-awake: systemd-inhibit here, plus a Wayland IdleInhibitor in Control Center, which has a window.
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

  // pdeathsig so a crashed crux can't leave the machine inhibited; systemd-inhibit stops sleep on SIGTERM.
  readonly property Process inhibitor: Process {
    running: root.active
    command: ["setpriv", "--pdeathsig", "TERM", "systemd-inhibit", "--what=idle:sleep", "--why=crux: keep awake", "--mode=block", "sleep", "infinity"]
  }
}
