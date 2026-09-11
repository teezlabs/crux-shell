import Quickshell.Io

// Backlight behavior.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property int step: 5 // % per scroll notch, Brightness.qml
    property bool enforceMinimum: true // never let brightnessctl hit 0%
}
