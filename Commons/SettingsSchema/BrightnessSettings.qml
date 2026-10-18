import Quickshell.Io

// Backlight behavior.
JsonObject {
    property int step: 5 // % per scroll notch, Brightness.qml
    property bool enforceMinimum: true // never let brightnessctl hit 0%
}
