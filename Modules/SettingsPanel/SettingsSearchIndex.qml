import QtQuick

// Static search index for the settings panel's fuzzy-search sidebar (see
// SettingsWindow.qml). Each entry: label + description (what's matched),
// the tab/subtab ids to navigate to, and optional extra keywords. This is
// crux's equivalent of noctalia's Assets/settings-search-index.json +
// i18n-key indirection — crux has plain strings, so the index lives
// inline as one readable list. Keep entries in sync when settings move or
// new tabs/subtabs land.
Item {
  id: root

  readonly property var entries: [
    // ---- General > Basics / Keybinds ----
    { "label": "Font family", "description": "Interface font used across the shell", "tab": "general", "subTab": "basics", "keywords": "font typeface" },
    { "label": "UI scale", "description": "Global multiplier for every font-size token", "tab": "general", "subTab": "basics", "keywords": "scale zoom size" },
    { "label": "Keybinds", "description": "Edit ~/.config/hypr/keybinds.lua, then hyprctl reload", "tab": "general", "subTab": "keybinds", "keywords": "shortcuts keys hyprland" },
    { "label": "Monospaced font", "description": "Font used by the keybinds viewer and hook command fields", "tab": "general", "subTab": "basics", "keywords": "font mono code" },
    { "label": "Reverse scrolling", "description": "Natural scroll direction, applied live via hyprctl", "tab": "general", "subTab": "basics", "keywords": "natural scroll direction touchpad mouse" },

    // ---- Bar > Layout / Widgets ----
    { "label": "Bar position", "description": "Which screen edge the bar sits on", "tab": "bar", "subTab": "layout", "keywords": "top bottom left right edge" },
    { "label": "Bar thickness", "description": "Cross-axis size of the bar strip", "tab": "bar", "subTab": "layout", "keywords": "size height width" },
    { "label": "Density presets", "description": "Comfortable/Compact bundle for thickness, spacing, and padding", "tab": "bar", "subTab": "layout", "keywords": "comfortable compact size" },
    { "label": "Widget spacing", "description": "Gap between bar widgets", "tab": "bar", "subTab": "layout", "keywords": "gap padding" },
    { "label": "Content padding", "description": "Inset between bar content and its edges", "tab": "bar", "subTab": "layout" },
    { "label": "Floating gap", "description": "Gap between the bar and the screen edge", "tab": "bar", "subTab": "layout", "keywords": "float margin" },
    { "label": "Auto-hide bar", "description": "Hide until the pointer touches the bar's screen edge", "tab": "bar", "subTab": "layout", "keywords": "autohide hide" },
    { "label": "Bar border", "description": "Show/hide and width of the bar's border", "tab": "bar", "subTab": "layout", "keywords": "outline stroke" },
    { "label": "Separate bar opacity", "description": "Use a dedicated background opacity instead of the theme's", "tab": "bar", "subTab": "layout", "keywords": "transparency alpha" },
    { "label": "Per-monitor bar overrides", "description": "Position and widgets per screen", "tab": "bar", "subTab": "layout", "keywords": "monitor screens dp-1 dp-2 override" },
    { "label": "Bar widgets", "description": "Add, remove and drag-reorder widgets on the bar", "tab": "bar", "subTab": "widgets", "keywords": "add remove reorder drag" },
    { "label": "Widget settings", "description": "Per-instance config for widgets like CustomButton and Spacer", "tab": "bar", "subTab": "widgets", "keywords": "edit custom button spacer" },

    // ---- Appearance > General / Colors ----
    { "label": "Appearance font", "description": "Font + scale for the whole shell", "tab": "appearance", "subTab": "general" },
    { "label": "Bar opacity", "description": "Background transparency of the bar and popups", "tab": "appearance", "subTab": "general", "keywords": "transparency alpha" },
    { "label": "Color presets", "description": "Built-in palette presets for the theme", "tab": "appearance", "subTab": "colors", "keywords": "palette scheme" },
    { "label": "Manual colors", "description": "Hand-pick individual theme role colors", "tab": "appearance", "subTab": "colors", "keywords": "palette hex" },
    { "label": "Dark mode", "description": "Switch between the cached dark and light theme branches", "tab": "appearance", "subTab": "colors", "keywords": "light theme" },

    // ---- Audio ----
    { "label": "Volume scroll step", "description": "Volume change per scroll notch / hardware key", "tab": "audio", "subTab": "", "keywords": "step increment" },
    { "label": "Output devices", "description": "Available audio outputs (shown in the sound popup)", "tab": "audio", "subTab": "", "keywords": "sink speaker" },
    { "label": "Input devices", "description": "Available audio inputs", "tab": "audio", "subTab": "", "keywords": "microphone source" },

    // ---- Display > Brightness / Night Light ----
    { "label": "Brightness", "description": "Internal backlight control via brightnessctl", "tab": "display", "subTab": "brightness", "keywords": "backlight screen" },
    { "label": "Brightness scroll step", "description": "% change per scroll notch", "tab": "display", "subTab": "brightness" },
    { "label": "Enforce minimum brightness", "description": "Never let brightness drop to an unrecoverable 0%", "tab": "display", "subTab": "brightness", "keywords": "min guard" },
    { "label": "Night light", "description": "Blue-light filter backed by wlsunset", "tab": "display", "subTab": "nightLight", "keywords": "blue light filter gamma" },
    { "label": "Force night light now", "description": "Bypass the schedule and apply night temperature immediately", "tab": "display", "subTab": "nightLight", "keywords": "force override" },
    { "label": "Night/day temperature", "description": "Kelvin for the night and day color temperatures", "tab": "display", "subTab": "nightLight", "keywords": "kelvin temp" },
    { "label": "Night light schedule", "description": "Manual sunrise and sunset times", "tab": "display", "subTab": "nightLight", "keywords": "sunrise sunset schedule" },

    // ---- Hue ----
    { "label": "Hue bridge", "description": "Philips Hue bridge IP and authentication", "tab": "hue", "subTab": "", "keywords": "philips lights" },
    { "label": "Hue rooms & zones", "description": "Pick which Hue group the bar widget controls", "tab": "hue", "subTab": "", "keywords": "group light" },

    // ---- System Monitor ----
    { "label": "System monitor sampling", "description": "How often CPU/RAM stats refresh", "tab": "systemMonitor", "subTab": "", "keywords": "refresh interval cpu ram" },
    { "label": "System monitor warn threshold", "description": "% at which CPU/RAM reads as warning-colored", "tab": "systemMonitor", "subTab": "", "keywords": "warning" },
    { "label": "Battery thresholds", "description": "Low and critical percent for battery color states", "tab": "systemMonitor", "subTab": "", "keywords": "low critical" },
    { "label": "Power profile", "description": "PowerSaver/Balanced/Performance switcher in the battery popup", "tab": "systemMonitor", "subTab": "", "keywords": "powerprofilesctl performance" },

    // ---- Peripherals ----
    { "label": "Keyboard device", "description": "Physical keyboard selection for layout and lock-key widgets", "tab": "peripherals", "subTab": "", "keywords": "device name input" },
    { "label": "Lock key indicators", "description": "Show Caps/Num/Scroll Lock indicators, hide when off", "tab": "peripherals", "subTab": "", "keywords": "capslock numlock scrolllock" },
    { "label": "VPN connections", "description": "Configured NetworkManager VPN profiles", "tab": "peripherals", "subTab": "", "keywords": "vpn wireguard nmcli" },

    // ---- Control Center ----
    { "label": "Show weather card", "description": "Toggle the forecast card in the Control Center popup", "tab": "controlCenter", "subTab": "", "keywords": "forecast weather" },
    { "label": "Temperature unit", "description": "Fahrenheit or Celsius for the weather card", "tab": "controlCenter", "subTab": "", "keywords": "fahrenheit celsius degrees" },
    { "label": "Control Center refresh interval", "description": "How often the CPU/MEM/TEMP/DISK gauges refresh", "tab": "controlCenter", "subTab": "", "keywords": "stats gauges cpu mem temp disk" },
    { "label": "Screenshot command", "description": "Command run by the CAPTURE action tile", "tab": "controlCenter", "subTab": "", "keywords": "capture rishot screenshot" },

    // ---- Wallpaper ----
    { "label": "Wallpaper directory", "description": "Where the wallpaper picker looks for images", "tab": "wallpaper", "subTab": "", "keywords": "folder images" },
    { "label": "Auto-theme", "description": "Regenerate theme colors from the wallpaper on pick", "tab": "wallpaper", "subTab": "", "keywords": "matugen colors" },
    { "label": "Theme generation", "description": "Matugen scheme and source-color index", "tab": "wallpaper", "subTab": "", "keywords": "matugen scheme color index" },
    { "label": "System templates", "description": "Write theme colors into app configs (kitty, GTK, Qt, yazi, ...)", "tab": "wallpaper", "subTab": "", "keywords": "kitty gtk qt yazi discord pywalfox btop starship hyprland" },
    { "label": "Sync system theme (gsettings)", "description": "Sets color-scheme prefer-dark so GTK4/libadwaita apps render dark", "tab": "wallpaper", "subTab": "", "keywords": "gnome gtk dark mode adwaita" },

    // ---- Desktop Widgets ----
    { "label": "Desktop widgets", "description": "Weather and now-playing cards pinned to the desktop", "tab": "desktopWidgets", "subTab": "", "keywords": "desktop cards" },
    { "label": "Weather card", "description": "Show/hide and position of the weather card", "tab": "desktopWidgets", "subTab": "" },
    { "label": "Media card", "description": "Show/hide and position of the now-playing card", "tab": "desktopWidgets", "subTab": "", "keywords": "now playing" },

    // ---- OSD ----
    { "label": "Volume OSD", "description": "Volume overlay — enabled, position, duration", "tab": "osd", "subTab": "", "keywords": "overlay popup" },

    // ---- Session Menu ----
    { "label": "Session menu actions", "description": "Which power actions show and which need a confirm tap", "tab": "sessionMenu", "subTab": "", "keywords": "power lock suspend logout reboot shutdown confirm" },

    // ---- Plugins ----
    { "label": "Plugins", "description": "Discovered and enabled local plugins", "tab": "plugins", "subTab": "", "keywords": "extensions add" },

    // ---- About ----
    { "label": "About crux", "description": "Version, config paths, restart the shell", "tab": "about", "subTab": "", "keywords": "version info restart reload" },

    // ---- Lock Screen ----
    { "label": "Lock screen clock", "description": "Time and date format on the lock screen", "tab": "lockScreen", "subTab": "appearance", "keywords": "time format clock" },
    { "label": "Lock screen blur", "description": "How much the background blurs when locked", "tab": "lockScreen", "subTab": "appearance" },
    { "label": "Lock screen dim", "description": "How dark the dim overlay is when locked", "tab": "lockScreen", "subTab": "appearance" },
    { "label": "Lock screen wallpaper", "description": "Custom wallpaper for the lock screen", "tab": "lockScreen", "subTab": "appearance", "keywords": "image path" },
    { "label": "Lock screen status row", "description": "Battery, network, volume and notification chips", "tab": "lockScreen", "subTab": "appearance", "keywords": "battery network volume notifications" },
    { "label": "Lock screen grace period", "description": "Seconds where Enter unlocks without a password", "tab": "lockScreen", "subTab": "behavior", "keywords": "grace password" },
    { "label": "Lock screen failed attempts", "description": "Max wrong attempts and lockout duration", "tab": "lockScreen", "subTab": "behavior", "keywords": "lockout brute force" },
    { "label": "Lock screen monitors", "description": "Which screens show the interactive unlock form", "tab": "lockScreen", "subTab": "monitors", "keywords": "interactive" },

    // ---- Notifications ----
    { "label": "Notifications", "description": "Master switch for the live notification popups", "tab": "notifications", "subTab": "general", "keywords": "notif enable" },
    { "label": "Do not disturb", "description": "Suppress new popups (still logged to history)", "tab": "notifications", "subTab": "general", "keywords": "dnd mute quiet" },
    { "label": "Notification position", "description": "Screen corner the popups appear in", "tab": "notifications", "subTab": "general", "keywords": "corner placement" },
    { "label": "Max visible notifications", "description": "How many popups stack before collapsing", "tab": "notifications", "subTab": "general" },
    { "label": "Notification durations", "description": "Auto-dismiss time per urgency, respect app timeout", "tab": "notifications", "subTab": "duration", "keywords": "auto dismiss timeout" },
    { "label": "Notification history", "description": "History size cap and retention", "tab": "notifications", "subTab": "history", "keywords": "log retention limit" },

    // ---- Idle ----
    { "label": "Idle handling", "description": "Screen off, lock and suspend timeouts", "tab": "idle", "subTab": "behavior", "keywords": "timeout dim lock suspend dpms" },
    { "label": "Idle grace delay", "description": "Activity grace before an idle stage fires", "tab": "idle", "subTab": "behavior" },
    { "label": "Idle commands", "description": "Override the commands for screen off, lock and suspend", "tab": "idle", "subTab": "behavior", "keywords": "command resume" },
    { "label": "Custom idle commands", "description": "Arbitrary commands with their own timeouts", "tab": "idle", "subTab": "custom", "keywords": "custom timeouts" },

    // ---- Hooks ----
    { "label": "Hooks", "description": "Master switch for all pre/post-action shell hooks", "tab": "hooks", "subTab": "general", "keywords": "scripts enable" },
    { "label": "Hook placeholders", "description": "What $1/$2/$3 mean in each hook", "tab": "hooks", "subTab": "general", "keywords": "variables args" },
    { "label": "Startup hook", "description": "Shell command run once when crux boots", "tab": "hooks", "subTab": "hooks", "keywords": "on start boot" },
    { "label": "Wallpaper hook", "description": "Shell command run when the wallpaper changes", "tab": "hooks", "subTab": "hooks", "keywords": "wallpaper changed" },
    { "label": "Color generation hook", "description": "Shell command run after matugen regenerates colors", "tab": "hooks", "subTab": "hooks", "keywords": "colors generated matugen" },
    { "label": "Dark mode hook", "description": "Shell command run when dark/light mode switches", "tab": "hooks", "subTab": "hooks", "keywords": "theme toggle" },
    { "label": "Lock/unlock hooks", "description": "Shell commands run when the screen locks and unlocks", "tab": "hooks", "subTab": "hooks", "keywords": "screen lock unlock" },
    { "label": "Session hook", "description": "Shell command run before power-menu actions", "tab": "hooks", "subTab": "hooks", "keywords": "power menu action" }
  ]
}
