pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

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

    property JsonObject bar: JsonObject {
      property string position: "top" // "top" | "bottom" | "left" | "right"
      property list<string> monitors: [] // empty = show on all monitors
      property int widgetSpacing: 6
      property int contentPadding: 2
      property int thickness: 32 // cross-axis size (height when top/bottom, width when left/right)
      property int floatMargin: 6 // gap between the bar and the screen edge on every side
      property bool showBorder: true
      property real borderWidth: 1
      property bool autoHide: false // hide until the pointer touches the bar's screen edge

      // Per-section widget lists: [{ "id": "Clock" }, ...]. Order = render order.
      property JsonObject widgets: JsonObject {
        property list<var> left: []
        property list<var> center: []
        property list<var> right: []
      }

      // Per-monitor overrides: [{ "name": "DP-1", "enabled": true, "position": "left", "widgets": {...} }]
      property list<var> screenOverrides: []
    }

    property JsonObject wallpaper: JsonObject {
      property string path: "" // current wallpaper, set live via `qs ipc call wallpaper set <path>`
      property string directory: (Quickshell.env("HOME") || "") + "/.config/wallpapers"
    }

    property JsonObject ui: JsonObject {
      property string fontFamily: "Departure Mono"
    }

    property JsonObject audio: JsonObject {
      property real step: 0.05 // volume change per scroll notch / hardware key press
    }

    property JsonObject systemMonitor: JsonObject {
      property int refreshInterval: 2000 // ms between /proc/stat and /proc/meminfo reads
      property int warnThreshold: 85 // % — CPU or RAM at/above this turns the readout mError-colored
    }

    // Semantic color tokens, Material-You-ish naming to match noctalia's
    // Commons/Color.qml convention (the "m" prefix avoids QML reading
    // e.g. "onPrimary" as a signal handler name). Defaults are exactly
    // the palette every crux widget has already been hardcoding all
    // along — this section makes it configurable, not a visual reset.
    property JsonObject theme: JsonObject {
      property string mPrimary: "#89b4fa" // accent
      property string mOnPrimary: "#1e1e2e"
      property string mSecondary: "#f38ba8" // warning/error accent
      property string mOnSecondary: "#1e1e2e"
      property string mSurface: "#1e1e2e" // popup/card background
      property string mOnSurface: "#cdd6f4" // primary text
      property string mSurfaceVariant: "#313244" // input fields, pills
      property string mOnSurfaceVariant: "#6c7086" // secondary/muted text
      property string mOutline: "#45475a" // borders, hover fill
      property string mError: "#f38ba8"
      property string mOnError: "#1e1e2e"

      property real radiusRatio: 1.0 // multiplies every Style.radius* token
      property real barOpacity: 1.0 // 0..1, bar + popup background alpha
    }
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

  function getBarWidgetsForScreen(screenName) {
    var override = _findScreenOverride(screenName);
    if (override && override.enabled !== false && override.widgets !== undefined) {
      return override.widgets;
    }
    return data.bar.widgets;
  }

  // Moves the widget at fromIndex to toIndex within one section, on whichever
  // widget list is actually effective for this screen (a screen override's
  // own widgets if it has one, else the global list) — same resolution rule
  // getBarWidgetsForScreen() uses, so a drag on the bar edits what's really
  // showing there.
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
}
