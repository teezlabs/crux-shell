import Quickshell.Io

// Clipboard history limits.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property int historyLimit: 50 // entries shown/kept in the popup, sliced client-side from cliphist's own list
}
