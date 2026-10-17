pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Loads crux's Hyprland shader overrides so windows get per-corner chamfers. See docs/hyprland.md.
Singleton {
  id: root

  function init(): void {
    reloadProc.running = true;
  }

  Process {
    id: reloadProc
    command: ["hyprctl", "reloadshaders", Quickshell.shellDir + "/Assets/hypr-shaders"]
    stdout: StdioCollector {
      id: reloadOut
      waitForEnd: true
    }
    onExited: function (exitCode) {
      if (exitCode !== 0 || reloadOut.text.trim() !== "ok")
        console.warn("WindowCorners: hyprctl reloadshaders failed:", reloadOut.text.trim());
    }
  }
}
