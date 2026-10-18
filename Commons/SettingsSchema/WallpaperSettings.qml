import Quickshell
import Quickshell.Io

// Wallpaper source, matugen theming, switch transition and auto-cycle.
JsonObject {
    property string path: "" // current wallpaper, set live via `qs ipc call wallpaper set <path>`
    property string directory: (Quickshell.env("HOME") || "") + "/.config/wallpapers"
    // Per-monitor overrides: [{ "name": "DP-1", "path": "..." }]; unlisted screens follow path.
    property list<var> screenOverrides: []
    property bool autoTheme: true // regenerate theme colors (via matugen) whenever a wallpaper is picked

    // Close the browser once a wallpaper is applied. Off so several can be compared in a row.
    property bool closeOnSelect: false

    // scheme-fidelity keeps the wallpaper's saturation instead of tonal-spot's muted look.
    property string matugenScheme: "scheme-fidelity"
    // matugen --source-color-index: which dominant colour to theme from (0 = most dominant, up to 4).
    property int matugenColorIndex: 0

    // Rotate to a random wallpaper from directory on a timer, through the same path as a manual pick.
    property bool autoCycle: false
    property int autoCycleMinutes: 30
    property string autoCycleMode: "random" // "random" | "sequential"

    // Wallhaven purity bitmask (sfw/sketchy/nsfw). NSFW needs an API key to return anything.
    property bool wallhavenSfw: true
    property bool wallhavenSketchy: false
    property bool wallhavenNsfw: false
    // From wallhaven.cc/settings/account; needed for NSFW and the account's own filters.
    property string wallhavenApiKey: ""
    // Wallhaven atleast (minimum resolution) and ratios; "" = no filter.
    property string wallhavenAtLeast: ""
    property string wallhavenRatio: ""

    // Shader transitions (Background.qml); with more than one checked, each switch picks at random.
    property list<string> transitionType: ["fade"]
    property int transitionDuration: 700 // ms
    property real transitionEdgeSmoothness: 0.05 // wipe/disc/stripes edge softness

    // App retheming via bin/theme-templates and Services/Matugen.qml. Each writes a real app config, so all start off.
    property JsonObject templates: JsonObject {
      property bool hyprland: false
      property bool kitty: false
      property bool gtk: false
      property bool qt: false
      property bool yazi: false
      property bool discord: false
      property bool pywalfox: false
      property bool btop: false
      property bool starship: false
      // Accent trio for the local startpage served on :8080.
      property bool startpage: false
      // Syncs the crux SDDM theme's background and colours (bin/crux-sync-greeter).
      property bool sddmGreeter: false
      // gsettings color-scheme=prefer-dark, which GTK4/libadwaita apps read for dark chrome.
      property bool gsettings: false
    }
}
