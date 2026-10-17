import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Widgets
import qs.Commons
import qs.Modules.ControlCenter
import qs.Widgets

// Wi-Fi quick toggle. Tapping asks the Control Center to expand the network
// list inline rather than opening a separate popup.
CcCircleToggle {
  id: tile
  signal expandRequested(string which)

  active: Networking.wifiEnabled
  onTapped: tile.expandRequested("wifi")

  WifiGlyph {
    anchors.centerIn: parent
    color: tile.active ? Colors.primaryText : Colors.surfaceText
  }
}
