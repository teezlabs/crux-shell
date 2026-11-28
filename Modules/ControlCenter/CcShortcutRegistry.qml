pragma Singleton

import QtQuick

// Shortcut button ids Control Center may show. What each one does lives in ControlCenterPopupContent.runShortcut().
QtObject {
  readonly property var ids: ["Screenshot", "Record", "ColorPicker", "Clipboard", "Wallpaper", "Lock", "Launcher", "Notifications"]

  readonly property var labels: ({
      "Screenshot": "Screenshot",
      "Record": "Record screen",
      "ColorPicker": "Pick a color",
      "Clipboard": "Clipboard",
      "Wallpaper": "Wallpaper",
      "Lock": "Lock",
      "Launcher": "Launcher",
      "Notifications": "Notifications"
    })

  readonly property var symbols: ({
      "Screenshot": "screenshot_region",
      "Record": "radio_button_checked",
      "ColorPicker": "colorize",
      "Clipboard": "content_paste",
      "Wallpaper": "wallpaper",
      "Lock": "lock",
      "Launcher": "search",
      "Notifications": "notifications"
    })

  function has(id) {
    return ids.indexOf(id) !== -1;
  }

  function labelFor(id) {
    return labels[id] || id;
  }

  function symbolFor(id) {
    return symbols[id] || "";
  }
}
