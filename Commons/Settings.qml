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

      // Per-section widget lists: [{ "id": "Clock" }, ...]. Order = render order.
      property JsonObject widgets: JsonObject {
        property list<var> left: []
        property list<var> center: []
        property list<var> right: []
      }

      // Per-monitor overrides: [{ "name": "DP-1", "enabled": true, "position": "left", "widgets": {...} }]
      property list<var> screenOverrides: []
    }

    property JsonObject ui: JsonObject {
      property string fontFamily: "Departure Mono"
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
