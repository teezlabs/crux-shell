import Quickshell.Io

// Idle timeouts and what each one does.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property bool enabled: true
    property int screenOffTimeoutSec: 300
    property int lockTimeoutSec: 600
    property int suspendTimeoutSec: 900
    property int fadeDurationSec: 10
    // "" falls back to Idle.qml's own built-in default for that stage;
    // resumeSuspendCommand has no built-in fallback (see Idle.qml).
    property string screenOffCommand: ""
    property string resumeScreenOffCommand: ""
    property string lockCommand: ""
    property string suspendCommand: ""
    property string resumeSuspendCommand: ""
    property string customCommands: "[]" // JSON-encoded array of extra {timeoutSec, command} entries
}
