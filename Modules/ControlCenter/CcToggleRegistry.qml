pragma Singleton

import QtQuick

// Toggle ids Control Center may show, each mapping to CcToggles/<id>.qml. An unlisted file is unreachable.
QtObject {
  readonly property var ids: ["Wifi", "Bluetooth", "Microphone", "NightLight", "KeepAwake", "PowerProfile", "DoNotDisturb", "GameMode", "Tailscale"]

  readonly property var labels: ({
      "Wifi": "Wi-Fi",
      "Bluetooth": "Bluetooth",
      "Microphone": "Microphone",
      "NightLight": "Night light",
      "KeepAwake": "Keep awake",
      "PowerProfile": "Power profile",
      "DoNotDisturb": "Do not disturb",
      "GameMode": "Game mode",
      "Tailscale": "Tailscale"
    })

  function has(id) {
    return ids.indexOf(id) !== -1;
  }

  function labelFor(id) {
    return labels[id] || id;
  }

  // Resolved here: Qt.resolvedUrl is relative to the calling file, which lives in Modules/Popups/Contents.
  function sourceFor(id) {
    return has(id) ? Qt.resolvedUrl("CcToggles/" + id + ".qml") : "";
  }
}
