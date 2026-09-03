import QtQuick
import Quickshell
import Quickshell.Networking
import Quickshell.Widgets
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// Wi-Fi quick toggle. Tapping asks the Control Center to expand the network
// list inline rather than opening a separate popup.
CcCircleToggle {
  id: tile
  signal expandRequested(string which)

  active: Networking.wifiEnabled
  onTapped: tile.expandRequested("wifi")

  NIcon {
    anchors.centerIn: parent
    width: 18
    height: 18
    iconName: tile.active ? "network-wireless-symbolic" : "network-wireless-disconnected-symbolic"
    // Non-symbolic name of the same icon: the convention every theme
    // follows, so a theme without the symbolic variant still renders.
    fallbackIconName: tile.active ? "network-wireless" : "network-wireless-disconnected"
    color: tile.active ? Color.primaryContainerText : Color.surfaceText
  }
}
