pragma Singleton

import QtQuick

// Quick toggles the Control Center is allowed to show. Each id maps to
// Modules/Bar/Extras/CcToggles/<id>.qml by convention — same arrangement as
// BarWidgetRegistry and the bar's widgets.
//
// Keep this in sync when adding a file there: an unlisted toggle can't be
// added from the settings panel and won't load if hand-seeded into
// settings.json.
QtObject {
  readonly property var ids: ["Wifi", "Bluetooth", "Microphone", "NightLight", "KeepAwake", "PowerProfile"]

  function has(id) {
    return ids.indexOf(id) !== -1;
  }
}
