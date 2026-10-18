import Quickshell.Io

// App launcher: fuzzy matching, result cap, run-command prefix.
JsonObject {
    property bool fuzzyMatch: false // false = the original plain substring filter
    property int resultLimit: 30
    property bool sortByMostUsed: false // empty-query list only -- a real search always sorts by match quality
    property string appUsageCounts: "{}" // JSON-encoded {appId: launchCount}, bumped in LauncherWindow.qml's launch()
    // A query starting with this runs it as a shell command instead of searching apps. "" disables it.
    property string execPrefix: ">"
}
