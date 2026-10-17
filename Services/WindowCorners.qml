pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Loads crux's Hyprland shader overrides so windows get per-corner chamfers. See docs/hyprland.md.
Singleton {
  id: root

  readonly property string sourceDir: Quickshell.shellDir + "/Assets/hypr-shaders"
  readonly property string shaderDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/crux/hypr-shaders"
  property bool pending: false

  function init(): void {
    root.apply();
  }

  function mask(): int {
    const c = Settings.data.windowCorners;
    return (c.cutTopLeft ? 1 : 0) | (c.cutTopRight ? 2 : 0) | (c.cutBottomRight ? 4 : 0) | (c.cutBottomLeft ? 8 : 0);
  }

  function apply(): void {
    if (!Settings.isLoaded)
      return;
    if (applyProc.running) {
      root.pending = true;
      return;
    }
    if (Settings.data.windowCorners.enabled)
      applyProc.command = ["bash", "-c", 'mkdir -p "$2" && cp "$1/border.glsl" "$1/quad.frag" "$2/" && sed "s/^#define CRUX_DEFAULT_MASK .*/#define CRUX_DEFAULT_MASK $3/" "$1/rounding.glsl" > "$2/rounding.glsl" && hyprctl reloadshaders "$2"', "bash", root.sourceDir, root.shaderDir, String(root.mask())];
    else
      applyProc.command = ["hyprctl", "reloadshaders"];
    applyProc.running = true;
  }

  readonly property Connections loadConn: Connections {
    target: Settings
    function onSettingsLoaded() {
      root.apply();
    }
  }

  readonly property Connections settingsConn: Connections {
    target: Settings.isLoaded ? Settings.data.windowCorners : null
    function onEnabledChanged() {
      root.apply();
    }
    function onCutTopLeftChanged() {
      root.apply();
    }
    function onCutTopRightChanged() {
      root.apply();
    }
    function onCutBottomRightChanged() {
      root.apply();
    }
    function onCutBottomLeftChanged() {
      root.apply();
    }
  }

  Process {
    id: applyProc
    stdout: StdioCollector {
      id: applyOut
      waitForEnd: true
    }
    onExited: function (exitCode) {
      if (exitCode !== 0 || applyOut.text.trim() !== "ok")
        console.warn("WindowCorners: hyprctl reloadshaders failed:", applyOut.text.trim());
      if (root.pending) {
        root.pending = false;
        root.apply();
      }
    }
  }
}
