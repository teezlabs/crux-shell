import Quickshell.Io

// Caps/num/scroll lock indicator.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property bool showCapsLock: true
    property bool showNumLock: true
    property bool showScrollLock: true
    property bool hideWhenOff: false // hide each indicator entirely instead of dimming it when its lock is off
}
