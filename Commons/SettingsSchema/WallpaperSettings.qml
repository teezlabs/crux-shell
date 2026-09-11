import Quickshell
import Quickshell.Io

// Wallpaper source, matugen theming, switch transition and auto-cycle.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property string path: "" // current wallpaper, set live via `qs ipc call wallpaper set <path>`
    property string directory: (Quickshell.env("HOME") || "") + "/.config/wallpapers"
    // Per-monitor override: [{ "name": "DP-1", "path": "..." }] — a screen
    // not listed here just follows `path` above. See getWallpaperForScreen.
    property list<var> screenOverrides: []
    property bool autoTheme: true // regenerate theme colors (via matugen) whenever a wallpaper is picked

    // scheme-fidelity (not Material 3's default scheme-tonal-spot) — stays
    // close to the wallpaper's own saturation instead of tonal-spot's
    // deliberately muted/desaturated look.
    property string matugenScheme: "scheme-fidelity"
    // matugen --source-color-index: which of an image's dominant candidate
    // colors to theme from (0 = most dominant, up to 4).
    property int matugenColorIndex: 0

    // Auto-cycle — noctalia's Wallpaper "Automation" subtab: rotate to a
    // new wallpaper from `directory` on a timer, same set+retheme path a
    // manual pick uses (see shell.qml's wallpaperCycleTimer).
    property bool autoCycle: false
    property int autoCycleMinutes: 30
    property string autoCycleMode: "random" // "random" | "sequential"

    // Wallhaven search purity filter (its `purity` param — a 3-digit
    // sfw/sketchy/nsfw bitmask). NSFW results require a Wallhaven account
    // API key to actually come back; the toggle still works, it just
    // won't return anything without one.
    property bool wallhavenSfw: true
    property bool wallhavenSketchy: false
    property bool wallhavenNsfw: false
    // From wallhaven.cc/settings/account — required for NSFW purity and
    // for it to respect the account's own browsing settings.
    property string wallhavenApiKey: ""
    // Wallhaven's `atleast` (minimum resolution, e.g. "1920x1080") and
    // `ratios` params — both "" means no filter.
    property string wallhavenAtLeast: ""
    property string wallhavenRatio: ""

    // Shader-based switch transition — see Background.qml / crux skill's
    // notes.md. List, not single value: >1 checked picks randomly per switch.
    property list<string> transitionType: ["fade"]
    property int transitionDuration: 700 // ms
    property real transitionEdgeSmoothness: 0.05 // wipe/disc/stripes edge softness

    // System-wide app retheming (bin/theme-templates/*, applied via
    // matugen --config in Commons/Matugen.qml). Off by default — each is
    // a real write to a real app's config file.
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
      // Syncs /usr/share/sddm/themes/crux's background + colors to
      // whatever's actually live — see bin/crux-sync-greeter.
      property bool sddmGreeter: false
      // Sets gsettings color-scheme=prefer-dark — what GTK4/libadwaita
      // apps check for dark chrome, independent of the gtk.css @import.
      property bool gsettings: false
    }
}
