import Quickshell.Io

// Fonts, type scale and the clock/date format tokens.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    // Bar clock format — a separate pair from lockScreen.clockFormat/
    // dateFormat below; the bar and lock screen are different surfaces
    // with their own space constraints, same reasoning that pair was
    // never shared with anything else either.
    property string clockFormat: "HH:mm"
    property string dateFormat: "ddd dd MMM"
    property string fontFamily: "Departure Mono"
    // Used only where code/commands are actually displayed (keybinds
    // viewer, hook command fields) — everything else stays on the one
    // shared fontFamily above. Not a general-purpose second font system;
    // crux has no per-role size scale to go with it, just the family.
    property string monoFontFamily: "Departure Mono"
    property real fontScale: 1.0 // multiplies every Tokens.*Size token
}
