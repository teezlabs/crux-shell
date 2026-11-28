import Quickshell.Io

// Control Center cards: which shortcuts and toggles, weather units, screenshot command.
JsonObject {
    property bool showWeather: true
    property string tempUnit: "fahrenheit" // "fahrenheit" | "celsius" — passed straight to open-meteo
    property string screenshotCommand: "rishot" // run (via sh -c) by the Screenshot shortcut button
    // Shortcut buttons under the profile row, in order. Ids from Modules/ControlCenter/CcShortcutRegistry.qml.
    property list<string> shortcuts: ["Screenshot", "Record", "ColorPicker", "Clipboard", "Wallpaper", "Lock"]
    // Toggle tiles under the shortcut buttons, in reading order. Ids from Modules/ControlCenter/CcToggleRegistry.qml.
    property list<string> toggles: ["Wifi", "Bluetooth", "Microphone", "NightLight"]
}
