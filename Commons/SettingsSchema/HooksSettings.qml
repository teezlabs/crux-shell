import Quickshell.Io

// User shell commands run on shell events.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property bool enabled: true
    // Each a shell command string, run via Hooks.qml; "" = no-op.
    property string startup: ""
    property string wallpaperChange: ""
    property string colorGeneration: ""
    property string darkModeChange: ""
    property string screenLock: ""
    property string screenUnlock: ""
    property string session: ""
}
