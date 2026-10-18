import Quickshell.Io

// Fonts, type scale and the clock/date format tokens.
JsonObject {
    // Bar clock format, separate from the lock screen's.
    property string clockFormat: "HH:mm"
    property string dateFormat: "ddd dd MMM"
    property string fontFamily: "Departure Mono"
    // Only where code or commands are shown (keybinds viewer, hook fields).
    property string monoFontFamily: "Departure Mono"
    property real fontScale: 1.0 // multiplies every Tokens.*Size token
}
