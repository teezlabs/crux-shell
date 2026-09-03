pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// power-profiles-daemon, via Quickshell's own UPower binding rather than
// shelling out to powerprofilesctl.
//
// `available` must stay a binding, never a snapshot: PowerProfiles reads
// its properties over DBus after construction, so hasPerformanceProfile is
// false for the first second or two of a session and then flips true.
// Anything gating visibility on a one-shot read of it stays hidden forever.
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

  function setProfile(p): void {
    if (!root.available)
      return;
    PowerProfiles.profile = p;
  }

  function cycle(): void {
    if (!root.available)
      return;
    const i = root.order.indexOf(root.profile);
    root.setProfile(root.order[(i + 1) % root.order.length]);
  }
}
