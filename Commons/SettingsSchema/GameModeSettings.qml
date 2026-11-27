import Quickshell.Io

// Game mode: whether it's on, and the Hyprland options and power profile it replaced, restored when it turns off.
JsonObject {
    property bool active: false
    property bool savedAnimations: true
    property bool savedBlur: true
    property bool savedShadow: false
    property string savedProfile: "" // PowerProfileService.key(); "" = leave the profile alone
}
