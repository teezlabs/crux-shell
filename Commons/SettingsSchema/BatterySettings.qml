import Quickshell.Io

// Battery thresholds and warnings.
JsonObject {
    property int lowThreshold: 20 // % — statusColor/low-state cutoff
    property int criticalThreshold: 10 // % — statusColor/critical-state cutoff
    property bool showPowerProfile: true // PowerProfiles switcher row in the battery popup
}
