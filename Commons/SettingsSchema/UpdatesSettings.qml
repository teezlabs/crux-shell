import Quickshell.Io

// Package update counter behavior.
JsonObject {
    property bool hideOnZero: true
    property int intervalMinutes: 20
    // "{}" is replaced with the command; without it the command is appended.
    property string terminalCommand: "kitty -- sh -c \"{}\""
    property string customCountCmd: ""
    property string customUpdateCmd: ""
}
