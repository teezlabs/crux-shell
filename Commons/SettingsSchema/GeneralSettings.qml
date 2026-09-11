import Quickshell.Io

// Shell-wide behavior that fits nowhere more specific.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property bool keepAwake: false // inhibit idle/screen-lock while true — Control Center toggle
    property string avatarImage: "" // "" = fall back to the Arch logo, the Control Center header avatar
    // Applied live via `hyprctl keyword input:natural_scroll` on toggle,
    // and re-applied on boot (see shell.qml) since Hyprland doesn't
    // persist this itself — it's a runtime keyword, not read from
    // hyprland.lua.
    property bool reverseScroll: false
}
