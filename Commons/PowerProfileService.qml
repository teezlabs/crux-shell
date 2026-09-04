pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// power-profiles-daemon via Quickshell's UPower binding. `available` must
// stay a binding, and a profile write can be refused by polkit — see the
// crux skill's notes.md.
Singleton {
  id: root

  readonly property bool available: PowerProfiles.hasPerformanceProfile
  readonly property int profile: PowerProfiles.profile
  // Non-zero when the daemon has throttled the machine (thermals, low
  // battery) and performance won't actually be delivered.
  readonly property bool degraded: PowerProfiles.degradationReason !== PerformanceDegradationReason.None

  // Ascending order, which is what a cycle and a segmented picker both want.
  readonly property var order: [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]

  function name(p): string {
    switch (p !== undefined ? p : root.profile) {
    case PowerProfile.Performance:
      return "Performance";
    case PowerProfile.Balanced:
      return "Balanced";
    case PowerProfile.PowerSaver:
      return "Power saver";
    }
    return "Unknown";
  }

  function key(p): string {
    switch (p !== undefined ? p : root.profile) {
    case PowerProfile.Performance:
      return "performance";
    case PowerProfile.Balanced:
      return "balanced";
    case PowerProfile.PowerSaver:
      return "power-saver";
    }
    return "balanced";
  }

  function fromKey(k): int {
    switch (k) {
    case "performance":
      return PowerProfile.Performance;
    case "power-saver":
      return PowerProfile.PowerSaver;
    }
    return PowerProfile.Balanced;
  }

  // Writing the profile is a polkit-gated DBus property write, and a
  // refusal surfaces only as a warning in the log — the property silently
  // keeps its old value. Verify the write actually took and say so if it
  // didn't, rather than leaving a bar icon that just doesn't respond.
  //
  // The usual cause is crux running outside the seated login session (a
  // terminal that puts itself in its own systemd scope, for instance):
  // power-profiles-daemon's switch-profile is allow_active, and polkit
  // resolves the session from the caller's cgroup.
  property int pendingProfile: -1

  function setProfile(p): void {
    if (!root.available)
      return;
    root.pendingProfile = p;
    PowerProfiles.profile = p;
    denialCheck.restart();
  }

  readonly property Timer denialCheck: Timer {
    interval: 400
    onTriggered: {
      if (root.pendingProfile < 0)
        return;
      if (PowerProfiles.profile !== root.pendingProfile)
        Toast.show("Not allowed to switch power profile");
      root.pendingProfile = -1;
    }
  }

  function cycle(): void {
    if (!root.available)
      return;
    const i = root.order.indexOf(root.profile);
    root.setProfile(root.order[(i + 1) % root.order.length]);
  }
}
