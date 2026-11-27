pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.Commons

// Game mode: Hyprland animations, blur and shadows off and the performance profile on; the old values come back on exit.
Singleton {
  id: root

  readonly property bool active: Settings.isLoaded && Settings.data.gameMode.active
  readonly property bool busy: readProc.running

  function toggle(): void {
    if (root.active)
      root.disable();
    else
      root.enable();
  }

  function enable(): void {
    if (root.active || readProc.running)
      return;
    readProc.verifyOnly = false;
    readProc.running = true;
  }

  function disable(): void {
    if (!root.active)
      return;
    const g = Settings.data.gameMode;
    root._apply(g.savedAnimations, g.savedBlur, g.savedShadow);
    if (g.savedProfile !== "" && PowerProfileService.available)
      PowerProfileService.setProfile(PowerProfileService.fromKey(g.savedProfile));
    g.active = false;
    Toast.show("Game mode off", 2000);
  }

  function _apply(animations, blur, shadow): void {
    Quickshell.execDetached(["hyprctl", "eval", "hl.config({ animations = { enabled = " + animations + " }, decoration = { blur = { enabled = " + blur + " }, shadow = { enabled = " + shadow + " } } })"]);
  }

  // Reads the three options in order; on enable the readings are saved before game mode overrides them.
  Process {
    id: readProc
    property bool verifyOnly: false
    command: ["sh", "-c", "for o in animations:enabled decoration:blur:enabled decoration:shadow:enabled; do hyprctl getoption \"$o\" -j; done"]
    stdout: StdioCollector {
      id: readOut
      waitForEnd: true
    }
    onExited: exitCode => {
      const vals = [];
      const re = /"bool":\s*(true|false)/g;
      let m;
      while ((m = re.exec(readOut.text)) !== null)
        vals.push(m[1] === "true");
      if (vals.length !== 3)
        return;
      const g = Settings.data.gameMode;
      if (readProc.verifyOnly) {
        // A new Hyprland session starts with animations back on; the saved state no longer applies.
        if (g.active && vals[0])
          g.active = false;
        return;
      }
      g.savedAnimations = vals[0];
      g.savedBlur = vals[1];
      g.savedShadow = vals[2];
      g.savedProfile = PowerProfileService.available ? PowerProfileService.key() : "";
      root._apply(false, false, false);
      if (PowerProfileService.available)
        PowerProfileService.setProfile(PowerProfile.Performance);
      g.active = true;
      Toast.show("Game mode on", 2000);
    }
  }

  Connections {
    target: Settings
    function onSettingsLoaded() {
      if (Settings.data.gameMode.active) {
        readProc.verifyOnly = true;
        readProc.running = true;
      }
    }
  }
}
