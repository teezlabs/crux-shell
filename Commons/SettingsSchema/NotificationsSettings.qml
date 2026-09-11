import Quickshell.Io

// Notification daemon behavior, placement and per-urgency timeouts.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property bool enabled: true
    property bool doNotDisturb: false
    property int maxVisible: 5
    property string position: "top_right" // "top_left" | "top_right" | "bottom_left" | "bottom_right"
    property int historyLimit: 50
    property int lowUrgencyDurationSec: 4
    property int normalUrgencyDurationSec: 6
    property int criticalUrgencyDurationSec: 0 // 0 = never auto-expire
    property bool respectAppExpireTimeout: true
    property real backgroundOpacity: 0.94
    property list<string> monitors: [] // empty = show on all monitors
}
