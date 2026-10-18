import Quickshell.Io

// Which session actions appear, and which need confirming.
JsonObject {
    property list<string> enabledActions: ["Lock", "Suspend", "Logout", "Reboot", "Shutdown"]
    property list<string> confirmActions: ["Logout", "Reboot", "Shutdown"]
    property int confirmWindowMs: 2500 // how long a "confirm" action stays armed after the first tap
}
