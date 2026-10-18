pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// User shell hooks run via `sh -lc` when hooks.enabled. Only the session hook blocks; the rest are fire-and-forget.
Singleton {
  id: root

  // True once Settings has loaded and init() ran, so values applied at boot don't count as changes.
  property bool _ready: false
  property bool _startupDone: false

  // ---- Firing points (live-bound to Settings.data) ----

  // Every wallpaper set goes through Settings.data.wallpaper.path, so watching it catches them all.
  Connections {
    target: Settings.data.wallpaper
    function onPathChanged() {
      if (root._ready && Settings.data.wallpaper.path)
        root.runWallpaperHook(Settings.data.wallpaper.path, "");
    }
  }

  // runDarkModeHook isn't called anywhere yet.

  Connections {
    target: Settings
    function onSettingsLoaded() {
      root._start();
    }
  }

  // ---- Helpers ----

  function _themeName() {
    return "dark";
  }

  function _enabled() {
    return Settings.data.hooks.enabled;
  }

  // ---- Hook runners, called by the wiring above and the settings panel's Test buttons ----

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

  // Blocking session hook: runs `script <action>` and calls back on exit; the power menu runs its action there.
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

  // Called from shell.qml's boot Timer; waits for Settings if init() beats the load.
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
