import Quickshell.Io

// Control Center cards: which toggles, weather units, capture command.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property bool showWeather: true
    property string tempUnit: "fahrenheit" // "fahrenheit" | "celsius" — passed straight to open-meteo
    property string screenshotCommand: "rishot" // run (via sh -c) by the CAPTURE action tile
    // Quick toggles shown in the top row, in order. Ids come from
    // Modules/ControlCenter/CcToggleRegistry.qml.
    property list<string> toggles: ["Wifi", "Bluetooth", "Microphone", "NightLight"]
}
