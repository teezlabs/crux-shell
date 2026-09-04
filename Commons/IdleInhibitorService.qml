pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Single owner of "keep the machine awake": the bar widget and the Control
// Center tile both drive this. Backed by a Wayland IdleInhibitor (in
// ControlCenterWindow, which has the window it needs) plus systemd-inhibit
// here. See the crux skill's notes.md.
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
