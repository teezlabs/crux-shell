pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons.SettingsSchema

// Lean JSON-backed settings store. Grows as crux needs more, not before.
Singleton {
  id: root

  property bool isLoaded: false
  property bool directoriesCreated: false

  readonly property alias data: adapter // Settings.data.bar.position, etc.

  readonly property string shellName: "crux"
  readonly property string configDir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/" + shellName + "/"
  readonly property string settingsFile: configDir + "settings.json"

  signal settingsLoaded

  Component.onCompleted: {
    Quickshell.execDetached(["mkdir", "-p", configDir]);
    directoriesCreated = true;
    settingsFileView.adapter = adapter;
  }

  // Debounce writes so rapid changes (drag reorder, slider drag) don't hammer disk.
  Timer {
    id: saveTimer
    interval: 300
    onTriggered: root.saveImmediate()
  }

  function saveImmediate() {
    settingsFileView.writeAdapter();
  }

  FileView {
    id: settingsFileView
    path: root.directoriesCreated ? root.settingsFile : undefined
    printErrors: false
    watchChanges: true
    onAdapterUpdated: saveTimer.restart()

    onPathChanged: if (path !== undefined) reload()

    onLoaded: {
      // One-time: module opacity used to follow theme.barOpacity unless overridden; it lives in bar.backgroundOpacity now.
      if (!adapter.bar.useSeparateOpacity) {
        adapter.bar.backgroundOpacity = adapter.theme.barOpacity;
        adapter.bar.useSeparateOpacity = true;
      }
      // One-time: text-on-fill colors used to live in the legacy mOnPrimary/mOnError roles.
      if (adapter.theme.primaryText === "")
        adapter.theme.primaryText = adapter.theme.mOnPrimary || adapter.theme.surface;
      if (adapter.theme.errorText === "")
        adapter.theme.errorText = adapter.theme.mOnError || adapter.theme.surface;
      if (!root.isLoaded) {
        root.isLoaded = true;
        root.settingsLoaded();
      }
    }
    onLoadFailed: function (error) {
      if (error.toString().includes("No such file") || error === 2) {
        // Fresh install: write current (default) adapter values as the file.
        writeAdapter();
      }
    }
  }

  JsonAdapter {
    id: adapter

    property JsonObject bar: BarSettings {}

    property JsonObject desktopWidgets: DesktopWidgetsSettings {}

    property JsonObject wallpaper: WallpaperSettings {}

    property JsonObject general: GeneralSettings {}

    property JsonObject ui: UiSettings {}

    property JsonObject launcher: LauncherSettings {}

    property JsonObject clipboard: ClipboardSettings {}

    // Genuinely missing until now: Battery.qml (bar widget) and
    // BatteryPopupContent.qml both read Settings.data.battery.* — always a
    // TypeError on every boot, not something introduced by the popup
    // rewrite, just never wired into the schema before.
    property JsonObject battery: BatterySettings {}

    property JsonObject audio: AudioSettings {}

    property JsonObject hue: HueSettings {}

    property JsonObject bluetooth: BluetoothSettings {}

    property JsonObject osd: OsdSettings {}

    // Which PowerMenuWindow actions are shown, and which require a second
    // tap within a short window before they actually run (arm-then-confirm,
    // simpler than a press-and-hold gesture but still catches fat-fingers
    // on anything destructive).
    property JsonObject sessionMenu: SessionMenuSettings {}

    property JsonObject systemMonitor: SystemMonitorSettings {}

    property JsonObject updates: UpdatesSettings {}

    property JsonObject controlCenter: ControlCenterSettings {}

    // Semantic color tokens ("m" prefix avoids QML reading "onPrimary" as
    // a signal handler name). Defaults match what every widget already
    // hardcoded — configurable, not a visual reset.
    property JsonObject theme: ThemeSettings {}

    property JsonObject brightness: BrightnessSettings {}

    property JsonObject nightLight: NightLightSettings {}

    property JsonObject hooks: HooksSettings {}

    property JsonObject idle: IdleSettings {}

    property JsonObject lockScreen: LockScreenSettings {}

    property JsonObject notifications: NotificationsSettings {}

    property JsonObject keyboard: KeyboardSettings {}

    property JsonObject lockKeys: LockKeysSettings {}

    // Marketplace sources for Commons/Plugins.qml -- each a git repo with
    // a registry.json at its root listing {id, label, description, ...}
    // per plugin. Local-folder plugins (no source) still work as before.
    property JsonObject plugins: PluginsSettings {}

    property JsonObject windowCorners: WindowCornersSettings {}
  }

  // -----------------------------------------------------
  // Per-screen resolution (falls back to the global bar.* value)

  function _findScreenOverride(screenName) {
    var overrides = data.bar.screenOverrides;
    if (!screenName || !overrides || overrides.length === undefined) {
      return null;
    }
    for (var i = 0; i < overrides.length; i++) {
      if (overrides[i] && overrides[i].name === screenName) {
        return overrides[i];
      }
    }
    return null;
  }

  function getBarPositionForScreen(screenName) {
    var override = _findScreenOverride(screenName);
    if (override && override.enabled !== false && override.position !== undefined) {
      return override.position;
    }
    return data.bar.position || "top";
  }

  // True if this screen has its own enabled position override (as opposed
  // to just following data.bar.position globally) — for the settings
  // panel's per-monitor override UI to know whether to show it as "custom".
  function hasPositionOverride(screenName) {
    var override = _findScreenOverride(screenName);
    return !!(override && override.enabled !== false && override.position !== undefined);
  }

  function getBarWidgetsForScreen(screenName) {
    var override = _findScreenOverride(screenName);
    if (override && override.enabled !== false && override.widgets !== undefined) {
      return override.widgets;
    }
    return data.bar.widgets;
  }

  // Moves a widget within one section, on whichever list is actually
  // effective for this screen — same resolution rule getBarWidgetsForScreen() uses.
  function reorderBarWidget(screenName, section, fromIndex, toIndex) {
    if (fromIndex === toIndex)
      return;

    var override = _findScreenOverride(screenName);
    var usesOverride = !!(override && override.enabled !== false && override.widgets !== undefined);
    var widgets = JSON.parse(JSON.stringify(usesOverride ? override.widgets : data.bar.widgets));
    var list = widgets[section];
    // toIndex === list.length is valid — "move to the end".
    if (!list || fromIndex < 0 || fromIndex >= list.length || toIndex < 0 || toIndex > list.length)
      return;

    var moved = list.splice(fromIndex, 1)[0];
    list.splice(toIndex, 0, moved);

    if (usesOverride) {
      setScreenOverride(screenName, "widgets", widgets);
    } else {
      // bar.widgets is a JsonObject, not a plain list<var> — reassigning the
      // whole object (data.bar.widgets = widgets) silently doesn't persist.
      // Assign directly to the affected list<var> sub-property instead,
      // same as how screenOverrides (itself a list<var>) is written above.
      data.bar.widgets[section] = list;
    }
  }

  // Moves the widget at fromIndex in fromSection to toIndex in toSection —
  // the cross-section counterpart to reorderBarWidget above. Same
  // effective-list resolution rule.
  function moveBarWidget(screenName, fromSection, fromIndex, toSection, toIndex) {
    if (fromSection === toSection) {
      reorderBarWidget(screenName, fromSection, fromIndex, toIndex);
      return;
    }

    var override = _findScreenOverride(screenName);
    var usesOverride = !!(override && override.enabled !== false && override.widgets !== undefined);
    var widgets = JSON.parse(JSON.stringify(usesOverride ? override.widgets : data.bar.widgets));
    var fromList = widgets[fromSection];
    var toList = widgets[toSection];
    if (!fromList || !toList || fromIndex < 0 || fromIndex >= fromList.length)
      return;

    var moved = fromList.splice(fromIndex, 1)[0];
    var insertAt = Math.max(0, Math.min(toIndex, toList.length));
    toList.splice(insertAt, 0, moved);
    widgets[fromSection] = fromList;
    widgets[toSection] = toList;

    if (usesOverride) {
      setScreenOverride(screenName, "widgets", widgets);
    } else {
      data.bar.widgets[fromSection] = fromList;
      data.bar.widgets[toSection] = toList;
    }
  }

  // Appends a widget id to the end of one section — for the settings
  // panel's "add widget" control. Same effective-list resolution rule.
  // Control Center quick toggles. A plain ordered list — no per-screen
  // overrides, unlike the bar's widgets.
  //
  // Reassigning the whole list<string> property is what persists here;
  // mutating the array in place does not (same trap reorderBarWidget hit).
  // Unknown ids are the loader's problem to refuse (CcToggleRegistry lives
  // in Modules, and Commons shouldn't reach up into it).
  function addCcToggle(id) {
    const list = data.controlCenter.toggles.slice();
    if (list.indexOf(id) !== -1)
      return;
    list.push(id);
    data.controlCenter.toggles = list;
  }

  function removeCcToggle(index) {
    const list = data.controlCenter.toggles.slice();
    if (index < 0 || index >= list.length)
      return;
    list.splice(index, 1);
    data.controlCenter.toggles = list;
  }

  function moveCcToggle(index, delta) {
    const list = data.controlCenter.toggles.slice();
    const to = index + delta;
    if (index < 0 || index >= list.length || to < 0 || to >= list.length)
      return;
    const item = list.splice(index, 1)[0];
    list.splice(to, 0, item);
    data.controlCenter.toggles = list;
  }

  function addBarWidget(screenName, section, widgetId) {
    var override = _findScreenOverride(screenName);
    var usesOverride = !!(override && override.enabled !== false && override.widgets !== undefined);
    var widgets = JSON.parse(JSON.stringify(usesOverride ? override.widgets : data.bar.widgets));
    var list = widgets[section];
    if (!list)
      return;
    list.push({
      "id": widgetId
    });

    if (usesOverride) {
      setScreenOverride(screenName, "widgets", widgets);
    } else {
      data.bar.widgets[section] = list;
    }
  }

  // Removes the widget at index from one section — for the settings
  // panel's per-row remove button.
  function removeBarWidget(screenName, section, index) {
    var override = _findScreenOverride(screenName);
    var usesOverride = !!(override && override.enabled !== false && override.widgets !== undefined);
    var widgets = JSON.parse(JSON.stringify(usesOverride ? override.widgets : data.bar.widgets));
    var list = widgets[section];
    if (!list || index < 0 || index >= list.length)
      return;
    list.splice(index, 1);

    if (usesOverride) {
      setScreenOverride(screenName, "widgets", widgets);
    } else {
      data.bar.widgets[section] = list;
    }
  }

  // Merges `patch`'s keys into one widget's own settings entry — the
  // per-instance store behind widgetData (Tray's pinned list, a
  // CustomButton's command). Same effective-list resolution rule as the
  // reorder/add/remove functions above.
  function updateBarWidget(screenName, section, index, patch) {
    var override = _findScreenOverride(screenName);
    var usesOverride = !!(override && override.enabled !== false && override.widgets !== undefined);
    var widgets = JSON.parse(JSON.stringify(usesOverride ? override.widgets : data.bar.widgets));
    var list = widgets[section];
    if (!list || index < 0 || index >= list.length)
      return;
    for (var key in patch)
      list[index][key] = patch[key];

    if (usesOverride) {
      setScreenOverride(screenName, "widgets", widgets);
    } else {
      data.bar.widgets[section] = list;
    }
    root.saveImmediate();
  }

  // Sets one property on a screen's override entry, creating the entry if needed.
  function setScreenOverride(screenName, property, value) {
    if (!screenName)
      return;

    var overrides = JSON.parse(JSON.stringify(data.bar.screenOverrides || []));
    if (overrides.length === undefined) {
      overrides = [];
    }

    var index = -1;
    for (var i = 0; i < overrides.length; i++) {
      if (overrides[i] && overrides[i].name === screenName) {
        index = i;
        break;
      }
    }

    if (index === -1) {
      var newEntry = {
        "name": screenName
      };
      newEntry[property] = value;
      overrides.push(newEntry);
    } else {
      overrides[index][property] = value;
    }
    data.bar.screenOverrides = overrides;
  }

  // Falls back to the global wallpaper.path when screenName has no override.
  function getWallpaperForScreen(screenName) {
    var overrides = data.wallpaper.screenOverrides || [];
    for (var i = 0; i < overrides.length; i++) {
      if (overrides[i] && overrides[i].name === screenName && overrides[i].path)
        return overrides[i].path;
    }
    return data.wallpaper.path;
  }

  // screenName === "" (or falsy) sets the global wallpaper and clears every
  // screen's override, so "apply to all monitors" doesn't leave stale
  // per-monitor overrides shadowing it.
  function setWallpaperForScreen(screenName, path) {
    if (!screenName) {
      data.wallpaper.path = path;
      data.wallpaper.screenOverrides = [];
      return;
    }

    var overrides = JSON.parse(JSON.stringify(data.wallpaper.screenOverrides || []));
    var index = -1;
    for (var i = 0; i < overrides.length; i++) {
      if (overrides[i] && overrides[i].name === screenName) {
        index = i;
        break;
      }
    }
    if (index === -1)
      overrides.push({
        "name": screenName,
        "path": path
      });
    else
      overrides[index].path = path;
    data.wallpaper.screenOverrides = overrides;
  }
}
