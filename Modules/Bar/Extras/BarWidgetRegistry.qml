pragma Singleton

import QtQuick

// The list of widget ids the bar is allowed to load. Each id maps to
// Modules/Bar/Widgets/<id>.qml by convention. Keep this in sync when
// adding a widget file — an unlisted file is silently unreachable: it
// can't be added from the settings panel and won't load if hand-seeded
// into settings.json.
//
// "DarkMode" is deliberately absent: Modules/Bar/Widgets/DarkMode.qml
// exists but targets Settings.data.theme.darkMode / Matugen.setDarkMode(),
// neither of which is built — crux is dark-only for now (Matugen.qml).
// Register it once light/dark theming lands.
QtObject {
  readonly property var ids: ["ActiveWindow", "Battery", "Bluetooth", "Brightness", "ClaudeUsage", "Clipboard", "Clock", "ControlCenter", "CustomButton", "Hue", "KeepAwake", "KeyboardLayout", "Launcher", "Layout", "LockKeys", "Media", "Microphone", "Network", "NightLight", "NotificationHistory", "PowerButton", "PowerProfile", "Settings", "Sidebar", "Sound", "Spacer", "StatusGroup", "SystemMonitor", "Taskbar", "Tray", "VPN", "Wallpaper", "Wifi", "Workspaces"]

  function hasWidget(id) {
    return ids.indexOf(id) !== -1;
  }
}
