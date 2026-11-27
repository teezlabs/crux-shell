import Quickshell.Io

// Control Center's homelab card: hosts pinged while the panel is open, and the dashboard a click opens.
JsonObject {
    property list<string> hosts: [] // "name=address", in display order
    property string dashboardUrl: ""
}
