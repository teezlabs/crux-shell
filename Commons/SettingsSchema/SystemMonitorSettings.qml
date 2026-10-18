import Quickshell.Io

// Which telemetry the system monitor widget shows.
JsonObject {
    property int refreshInterval: 2000 // ms between /proc/stat and /proc/meminfo reads
    // Per-metric thresholds: CPU load and disk fullness don't warrant the same cutoff.
    property int cpuWarningThreshold: 80
    property int cpuCriticalThreshold: 90
    property int memWarningThreshold: 80
    property int memCriticalThreshold: 90
    property int diskWarningThreshold: 80
    property int diskCriticalThreshold: 90
    property int tempWarningThreshold: 80
    property int tempCriticalThreshold: 90
}
