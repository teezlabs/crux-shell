import Quickshell.Io

// On-screen display placement and timeout.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property bool enabled: true
    property string position: "bottom" // "top" | "center" | "bottom"
    property int durationMs: 1400 // spec §6.5: "Show 1.4s after the last input event"
    property real backgroundOpacity: 0.95 // was Tokens.panelOpacity, now user-adjustable
    property list<string> monitors: [] // empty = show on all monitors
}
