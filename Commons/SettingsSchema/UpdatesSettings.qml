import Quickshell.Io

// Package update counter behavior.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property bool hideOnZero: true
    property int intervalMinutes: 20
    // "{}" is replaced with the command to run; with no "{}" the command
    // is appended instead.
    property string terminalCommand: "kitty -- sh -c \"{}\""
    property string customCountCmd: ""
    property string customUpdateCmd: ""
}
