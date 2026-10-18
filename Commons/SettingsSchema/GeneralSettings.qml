import Quickshell.Io

// Shell-wide behavior that fits nowhere more specific.
JsonObject {
    property bool keepAwake: false // inhibit idle/screen-lock while true — Control Center toggle
    property string avatarImage: "" // "" = fall back to the Arch logo, the Control Center header avatar
    // A runtime Hyprland keyword, so shell.qml applies it live and again on boot.
    property bool reverseScroll: false
}
