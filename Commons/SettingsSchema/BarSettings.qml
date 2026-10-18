import Quickshell.Io

// The bar itself: placement, thickness, chrome, and the per-section widget lists.
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
    property bool useSeparateOpacity: false // migration flag: true once theme.barOpacity has been copied into backgroundOpacity
    property real backgroundOpacity: 1.0 // module plates and group surfaces

    // One chamfered surface per section with the widgets flat inside it, instead of a module per widget.
    property bool groupSections: true
    // Detached floating modules when true, a flush edge-to-edge strip when false.
    property bool floating: true
    // A real bar-strip background, separate from the per-module fill opacity.
    property bool showBackground: false
    property real barBackgroundOpacity: 0.85

    // Per-section widget lists in render order. The defaults give a fresh install a populated bar.
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
