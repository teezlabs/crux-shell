import Quickshell.Io

// Generated and hand-edited colors. Matugen writes here.
JsonObject {
    // Legacy: read once by Settings' migration into primaryText/errorText.
    property string mOnPrimary: ""
    property string mOnError: ""

    property real barOpacity: 1.0 // legacy: read once by Settings' migration into bar.backgroundOpacity

    // Tonal-spot roles (spec §1); the defaults are matugen's until a wallpaper regenerates them.
    property string surface: "#080B0E"
    property string surfaceContainerLow: "#0D1115"
    property string surfaceContainer: "#12171C"
    property string surfaceContainerHigh: "#1B2228"
    property string outline: "#333D45"
    property string outlineVariant: "#262E35"
    property string primary: "#7FD4E0"
    property string primaryContainer: "#1A4A52"
    property string primaryContainerText: "#B8ECF3"
    property string tertiary: "#D9BCC9"
    property string errorTone: "#F5A89F" // named errorTone, not error — JsonObject already has a built-in "error" signal
    property string surfaceText: "#DDE4E8"
    property string surfaceTextMuted: "#9AA5AC"
    // Readable text on primary and error fills.
    property string primaryText: ""
    property string errorText: ""

    // Applied Assets/ColorSchemes preset, "" when the colours came from matugen.
    property string colorScheme: ""

    // Which half of matugen's output the shell reads, and its --mode for templates.
    property bool darkMode: true
}
