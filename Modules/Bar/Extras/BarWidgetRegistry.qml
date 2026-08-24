pragma Singleton

import QtQuick

// The list of widget ids the bar is allowed to load. Each id maps to
// Modules/Bar/Widgets/<id>.qml by convention.
QtObject {
  readonly property var ids: ["Clock", "Workspaces", "PowerButton", "Wifi", "Bluetooth", "ClaudeUsage", "Clipboard", "Launcher", "Media", "SystemMonitor", "Settings", "Wallpaper", "Sound"]

  function hasWidget(id) {
    return ids.indexOf(id) !== -1;
  }
}
