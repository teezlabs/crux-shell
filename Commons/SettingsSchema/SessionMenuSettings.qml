import Quickshell.Io

// Which session actions appear, and which need confirming.
// Split out of Settings.qml; the JsonAdapter serializes this exactly as
// it did when the block was inline.
JsonObject {
    property list<string> enabledActions: ["Lock", "Suspend", "Logout", "Reboot", "Shutdown"]
    property list<string> confirmActions: ["Logout", "Reboot", "Shutdown"]
    property int confirmWindowMs: 2500 // how long a "confirm" action stays armed after the first tap
}
