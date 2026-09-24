import Quickshell.Io

// The bar itself: placement, thickness, chrome, and the per-section widget lists.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property string position: "top" // "top" | "bottom" | "left" | "right"
    property list<string> monitors: [] // empty = show on all monitors
    property int widgetSpacing: 6
    property int contentPadding: 2
    property int thickness: 32 // cross-axis size (height when top/bottom, width when left/right)
    property int floatMargin: 6 // gap between the bar and the screen edge on every side
    property bool showBorder: true
    property real borderWidth: 1
    property bool autoHide: false // hide until the pointer touches the bar's screen edge
    property bool useSeparateOpacity: false // false = follow theme.barOpacity
    property real backgroundOpacity: 1.0 // used only when useSeparateOpacity is true

    // One chamfered surface per section with the widgets flat inside it,
    // split by hairlines, instead of an outlined module per widget.
    property bool groupSections: true
    // Detached floating modules when true, flush edge-to-edge strip when
    // false — opt-in toggle, see crux skill's notes.md.
    property bool floating: true
    // A real bar-strip background (distinct from useSeparateOpacity/
    // backgroundOpacity above, which only ever affected each module's
    // own individual chamfer fill) — off by default, keeping the current
    // "transparent bar, edge-glow line only" look until turned on.
    property bool showBackground: false
    property real barBackgroundOpacity: 0.85

    // Per-section widget lists: [{ "id": "Clock" }, ...]. Order = render
    // order. Defaults give a fresh install (no settings.json yet) an
    // actual populated bar instead of a bare strip — confirmed real bug:
    // these were empty arrays, so a genuinely new install (the AUR
    // package, a second machine, anyone without a hand-tuned settings
    // file already) booted to a bar with nothing on it at all.
    property JsonObject widgets: JsonObject {
      property list<var> left: [{
          "id": "ControlCenter"
        }, {
          "id": "Launcher"
        }, {
          "id": "Workspaces"
        }]
      property list<var> center: [{
          "id": "Clock"
        }]
      property list<var> right: [{
          "id": "Tray"
        }, {
          "id": "StatusGroup"
        }, {
          "id": "Settings"
        }, {
          "id": "PowerButton"
        }]
    }

    // Per-monitor overrides: [{ "name": "DP-1", "enabled": true, "position": "left", "widgets": {...} }]
    property list<var> screenOverrides: []
}
