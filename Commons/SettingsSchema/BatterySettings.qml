import Quickshell.Io

// Battery thresholds and warnings.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property int lowThreshold: 20 // % — statusColor/low-state cutoff
    property int criticalThreshold: 10 // % — statusColor/critical-state cutoff
    property bool showPowerProfile: true // PowerProfiles switcher row in the battery popup
}
