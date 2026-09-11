import Quickshell.Io

// Which telemetry the system monitor widget shows.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property int refreshInterval: 2000 // ms between /proc/stat and /proc/meminfo reads
    // Per-metric warning/critical %, replacing one flat threshold for
    // every metric — CPU thermal headroom and disk fullness don't
    // usually warrant the same cutoff.
    property int cpuWarningThreshold: 80
    property int cpuCriticalThreshold: 90
    property int memWarningThreshold: 80
    property int memCriticalThreshold: 90
    property int diskWarningThreshold: 80
    property int diskCriticalThreshold: 90
    property int tempWarningThreshold: 80
    property int tempCriticalThreshold: 90
}
