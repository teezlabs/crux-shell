pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Pre/post-action shell hooks — ported from noctalia-shell's
// Services/Control/HooksService.qml. Every settings field
// (Settings.data.hooks.*) is a shell command string run via `sh -lc` at
// the corresponding moment, guarded by Settings.data.hooks.enabled.
// Placeholder substitution matches noctalia: each runner documents its
// $1/$2/$3 slots. The session hook is the one genuinely blocking one —
// power-menu actions wait for it to finish before running (noctalia's
// runPowerHook semantics); every other hook is fire-and-forget.
//
// Deliberately dropped from the noctalia original: the
// performanceModeEnabled/Disabled pair (crux has no performance-mode
// concept; the Battery popup's power-profiles switcher is a different
// thing) — the settings rows for those were dropped alongside them.
Singleton {
  id: root

  // Becomes true only once settings have actually loaded AND init() has
  // run — guards the live-bound wallpaper/darkMode Connections below
  // against firing on the initial FileView load (a saved wallpaper path
  // or darkMode value being applied at boot is not a "change").
  property bool _ready: false
  property bool _startupDone: false

  // ---- Firing points (live-bound to Settings.data) ----

  // Every wallpaper set routes through Settings.data.wallpaper.path
  // (shell.qml's `wallpaper` IPC, WallpaperTab's grid, the embedded skwd
  // picker's apply, WallpaperThemeStrip) — watching the property catches
  // all of them, no per-call-site wiring needed.
  Connections {
    target: Settings.data.wallpaper
    function onPathChanged() {
      if (root._ready && Settings.data.wallpaper.path)
        root.runWallpaperHook(Settings.data.wallpaper.path, "");
    }
  }

  // No dark/light-mode Connections here — crux has no such concept
  // (Matugen.qml only ever generates a dark palette), unlike noctalia's
  // original HooksService this was ported from. runDarkModeHook below
  // stays callable manually if that ever changes, it just never auto-fires.

  Connections {
    target: Settings
    function onSettingsLoaded() {
      root._start();
    }
  }

  // ---- Helpers ----

  function _themeName() {
    // crux has no light/dark toggle — always dark (see the Connections
    // comment above).
    return "dark";
  }

  function _enabled() {
    return Settings.data.hooks.enabled;
  }

  // ---- Individual hook runners (called by the wiring above and by the
  // settings panel's Test buttons) ----

  function runWallpaperHook(wallpaperPath, screenName) {
    if (!root._enabled())
      return;
    var script = Settings.data.hooks.wallpaperChange;
    if (!script || script === "")
      return;
    var command = script.replace(/\$1/g, wallpaperPath).replace(/\$2/g, screenName || "").replace(/\$3/g, root._themeName());
    Quickshell.execDetached(["sh", "-lc", command]);
  }

  function runColorGenerationHook() {
    if (!root._enabled())
      return;
    var script = Settings.data.hooks.colorGeneration;
    if (!script || script === "")
      return;
    Quickshell.execDetached(["sh", "-lc", script.replace(/\$1/g, root._themeName())]);
  }

  function runDarkModeHook(isDark) {
    if (!root._enabled())
      return;
    var script = Settings.data.hooks.darkModeChange;
    if (!script || script === "")
      return;
    Quickshell.execDetached(["sh", "-lc", script.replace(/\$1/g, isDark ? "true" : "false")]);
  }

  function runLockHook() {
    if (!root._enabled())
      return;
    var script = Settings.data.hooks.screenLock;
    if (!script || script === "")
      return;
    // $1 = "lock" via shell argv, same as noctalia's lock-hook invocation.
    Quickshell.execDetached(["sh", "-lc", script, "lock-hook", "lock"]);
  }

  function runUnlockHook() {
    if (!root._enabled())
      return;
    var script = Settings.data.hooks.screenUnlock;
    if (!script || script === "")
      return;
    Quickshell.execDetached(["sh", "-lc", script, "unlock-hook", "unlock"]);
  }

  function runStartupHook() {
    if (!root._enabled())
      return;
    var script = Settings.data.hooks.startup;
    if (!script || script === "")
      return;
    Quickshell.execDetached(["sh", "-lc", script]);
  }

  // Blocking session hook: runs `script <action>`, and only calls back
  // once the process exits (noctalia's runPowerHook contract). Callers —
  // the power menu's actions — run their real action in the callback.
  property var _pendingCallback: null

  Process {
    id: hookProc
    onExited: function (exitCode) {
      if (root._pendingCallback) {
        var cb = root._pendingCallback;
        root._pendingCallback = null;
        cb();
      }
    }
  }

  function runSessionHook(action, callback) {
    if (!root._enabled() || !Settings.data.hooks.session) {
      if (callback)
        callback();
      return;
    }
    root._pendingCallback = callback;
    hookProc.command = ["sh", "-lc", Settings.data.hooks.session + " " + action];
    hookProc.running = true;
  }

  // ---- Init ----

  // Called once from shell.qml's boot Timer (alongside Idle.init()). The
  // startup hook must not run until Settings is loaded (the script lives
  // in settings.json), so if init() beats the FileView load we wait for
  // Settings.settingsLoaded above.
  function _start() {
    root._ready = true;
    if (!root._startupDone) {
      root._startupDone = true;
      Qt.callLater(function () {
        root.runStartupHook();
      });
    }
  }

  function init() {
    if (Settings.isLoaded)
      root._start();
    else
      root._ready = false; // onSettingsLoaded will call _start
  }
}
