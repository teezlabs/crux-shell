pragma Singleton

import QtQuick

// Toggle ids Control Center may show, each mapping to CcToggles/<id>.qml. An unlisted file is unreachable.
QtObject {
  readonly property var ids: ["Wifi", "Bluetooth", "Microphone", "NightLight", "KeepAwake", "PowerProfile", "DoNotDisturb"]

  function has(id) {
    return ids.indexOf(id) !== -1;
  }

  // Resolved here: Qt.resolvedUrl is relative to the calling file, which lives in Modules/Popups/Contents.
  function sourceFor(id) {
    return has(id) ? Qt.resolvedUrl("CcToggles/" + id + ".qml") : "";
  }
}
