import QtQuick
import Quickshell.Bluetooth
import qs.Commons
import qs.Modules.ControlCenter

// Bluetooth tile: tap powers the adapter, the chevron opens the device page.
CcTile {
  id: tile
  signal expandRequested(string which)

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var connected: {
    const devices = Bluetooth.devices ? Bluetooth.devices.values : [];
    return devices.filter(d => d && d.connected);
  }

  symbol: !tile.active ? "bluetooth_disabled" : (tile.connected.length > 0 ? "bluetooth_connected" : "bluetooth")
  label: CcToggleRegistry.labelFor("Bluetooth")
  status: !tile.adapter ? "No adapter" : !tile.active ? "Off" : tile.connected.length === 1 ? tile.connected[0].name : tile.connected.length > 1 ? tile.connected.length + " devices" : "On"
  active: !!tile.adapter && tile.adapter.enabled
  available: !!tile.adapter
  expandable: true
  onTapped: tile.adapter.enabled = !tile.adapter.enabled
  onChevronTapped: tile.expandRequested("bluetooth")
}
