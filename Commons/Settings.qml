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

    property JsonObject battery: BatterySettings {}

    property JsonObject audio: AudioSettings {}

    property JsonObject hue: HueSettings {}

    property JsonObject bluetooth: BluetoothSettings {}

    property JsonObject osd: OsdSettings {}

    // Visible session actions, and which need a confirming second tap.
    property JsonObject sessionMenu: SessionMenuSettings {}

    property JsonObject systemMonitor: SystemMonitorSettings {}

    property JsonObject updates: UpdatesSettings {}

    property JsonObject controlCenter: ControlCenterSettings {}

    // Semantic colour roles read by Commons/Colors.qml.
    property JsonObject theme: ThemeSettings {}

    property JsonObject brightness: BrightnessSettings {}

    property JsonObject nightLight: NightLightSettings {}

    property JsonObject hooks: HooksSettings {}

    property JsonObject idle: IdleSettings {}

    property JsonObject lockScreen: LockScreenSettings {}

    property JsonObject notifications: NotificationsSettings {}

    property JsonObject keyboard: KeyboardSettings {}

    property JsonObject lockKeys: LockKeysSettings {}

    // Plugin marketplace sources: git repos with a registry.json at the root.
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

  // True if this screen has an enabled position override of its own.
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

  // Moves a widget within one section of the list this screen actually uses.
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
      // Assign the list<var> sub-property; reassigning the whole widgets JsonObject doesn't persist.
      data.bar.widgets[section] = list;
    }
  }

  // Cross-section counterpart to reorderBarWidget.
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

  // Control Center toggles are one plain list, with no per-screen overrides.
  // Reassign the whole list<string>; mutating it in place doesn't persist.
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

  // Appends a widget id to the end of one section.
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

  // Removes the widget at index from one section.
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

  // Merges patch into one widget's own entry, the per-instance store behind widgetData.
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

  // An empty screenName sets the global wallpaper and clears every per-screen override.
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
