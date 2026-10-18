pragma Singleton

import QtQuick

// Widget ids the bar may load, each mapping to Modules/Bar/Widgets/<id>.qml. An unlisted file is unreachable.

QtObject {
  readonly property var ids: ["ActiveWindow", "AudioVisualizer", "Battery", "Bluetooth", "Brightness", "ClaudeUsage", "Clipboard", "Clock", "ControlCenter", "CustomButton", "DarkMode", "Hue", "KeepAwake", "KeyboardLayout", "Launcher", "Layout", "LockKeys", "Media", "Microphone", "Network", "NightLight", "NotificationHistory", "PowerButton", "PowerProfile", "Settings", "Sidebar", "Sound", "Spacer", "StatusGroup", "SystemMonitor", "Taskbar", "Tray", "Updates", "VPN", "Wallpaper", "Wifi", "Workspaces"]

  function hasWidget(id) {
    return ids.indexOf(id) !== -1;
  }
}
