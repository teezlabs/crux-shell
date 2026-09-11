import QtQuick
import qs.Commons

// Every screen-agnostic popup IPC target, instantiated once for the whole
// shell (not per monitor) — see PopupAlias.qml for why that matters.
QtObject {
  id: root

  readonly property var names: ["sound", "battery", "bluetooth", "wifi", "hue", "microphone", "brightness", "clipboard", "claudeUsage", "notificationHistory", "systemStats", "controlCenter", "sidebar", "settings", "power", "wallpaperBrowser", "launcher", "calendar", "mediaPlayer"]

  readonly property Instantiator aliases: Instantiator {
    model: root.names
    delegate: PopupAlias {
      required property var modelData
      name: modelData
    }
  }
}
