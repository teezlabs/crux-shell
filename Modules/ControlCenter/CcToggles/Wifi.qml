import QtQuick
import Quickshell.Networking
import qs.Commons
import qs.Modules.ControlCenter

// Wi-Fi tile: tap switches the radio, the chevron pops the network list out beside the panel.
CcTile {
  id: tile
  signal expandRequested(string which)

  readonly property var device: {
    const devices = Networking.devices ? Networking.devices.values : [];
    return devices.find(d => d && d.type === DeviceType.Wifi) || null;
  }
  readonly property var network: {
    const networks = tile.device && tile.device.networks ? tile.device.networks.values : [];
    return networks.find(n => n && n.connected) || null;
  }

  symbol: Networking.wifiEnabled ? "wifi" : "wifi_off"
  label: "Wi-Fi"
  status: !Networking.wifiEnabled ? "Off" : (tile.network ? tile.network.name : "Not connected")
  active: Networking.wifiEnabled
  expandable: true
  onTapped: Networking.wifiEnabled = !Networking.wifiEnabled
  onChevronTapped: tile.expandRequested("wifi")
}
