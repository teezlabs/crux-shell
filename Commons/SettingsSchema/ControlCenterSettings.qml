import Quickshell.Io

// Control Center cards: which toggles, weather units, capture command.
JsonObject {
    property bool showWeather: true
    property string tempUnit: "fahrenheit" // "fahrenheit" | "celsius" — passed straight to open-meteo
    property string screenshotCommand: "rishot" // run (via sh -c) by the CAPTURE action tile
    // Toggle tiles under the shortcut buttons, in reading order. Ids from Modules/ControlCenter/CcToggleRegistry.qml.
    property list<string> toggles: ["Wifi", "Bluetooth", "Microphone", "NightLight"]
}
