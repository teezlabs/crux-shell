import Quickshell.Io

// Idle timeouts and what each one does.
JsonObject {
    property bool enabled: true
    property int screenOffTimeoutSec: 300
    property int lockTimeoutSec: 600
    property int suspendTimeoutSec: 900
    property int fadeDurationSec: 10
    // "" uses Idle.qml's built-in default; resumeSuspendCommand has none.
    property string screenOffCommand: ""
    property string resumeScreenOffCommand: ""
    property string lockCommand: ""
    property string suspendCommand: ""
    property string resumeSuspendCommand: ""
    property string customCommands: "[]" // JSON-encoded array of extra {timeoutSec, command} entries
}
