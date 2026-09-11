import Quickshell.Io

// Keyboard layout switching.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property string deviceName: "" // "" = follow Hyprland's default active keyboard
}
