pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.Commons

// power-profiles-daemon via UPower. `available` must stay a binding (docs/design-notes.md).
Singleton {
  id: root

  readonly property bool available: PowerProfiles.hasPerformanceProfile
  readonly property int profile: PowerProfiles.profile
  // The daemon has throttled the machine, so performance won't be delivered.
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

  // A polkit refusal only logs a warning and leaves the old value, so the write is verified (docs/design-notes.md).
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
