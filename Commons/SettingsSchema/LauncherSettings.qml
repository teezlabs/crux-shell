import Quickshell.Io

// App launcher: fuzzy matching, result cap, run-command prefix.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property bool fuzzyMatch: false // false = the original plain substring filter
    property int resultLimit: 30
    property bool sortByMostUsed: false // empty-query list only -- a real search always sorts by match quality
    property string appUsageCounts: "{}" // JSON-encoded {appId: launchCount}, bumped in LauncherWindow.qml's launch()
    // Typing this at the start of the query switches to "run this exact
    // shell command" mode instead of searching apps — LauncherWindow.qml
    // had a comment saying it was "apps-only today (no run/windows/calc
    // modes yet)"; this is that run mode. Empty string disables it.
    property string execPrefix: ">"
}
