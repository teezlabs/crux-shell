import Quickshell.Io

// User shell commands run on shell events.
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
