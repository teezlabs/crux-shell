import Quickshell.Io

// Lock screen appearance, behavior and per-monitor gating.
JsonObject {
    property string clockFormat: "HH:mm"
    property string dateFormat: "dddd d MMMM yyyy"
    property bool useCustomWallpaper: false
    property string customWallpaperPath: ""
    property real blurAmount: 1.0
    property real dimAmount: 0.35
    property bool showNetwork: true
    property bool showBattery: true
    property bool showVolume: true
    property bool showNotifications: true
    property bool showMediaControls: true // read-only now-playing line, not interactive -- no new tappable surface on the lock screen
    property int gracePeriodSec: 0 // 0 = off, no delay before the lock actually engages
    property int maxFailedAttempts: 0 // 0 = unlimited
    property int lockoutDurationSec: 30
    property list<string> monitors: [] // empty = show on all monitors
}
