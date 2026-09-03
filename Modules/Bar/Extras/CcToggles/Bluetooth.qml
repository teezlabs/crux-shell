import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets
import qs.Commons
import qs.Modules.Bar.Extras

// Bluetooth quick toggle. Tapping expands the device list inline.
CcCircleToggle {
  id: tile
  signal expandRequested(string which)

  readonly property var adapter: Bluetooth.defaultAdapter
  active: !!adapter && adapter.enabled
  available: !!adapter
  onTapped: tile.expandRequested("bluetooth")

  IconImage {
    anchors.centerIn: parent
    width: 16
    height: 16
    source: Quickshell.iconPath(tile.active ? "preferences-system-bluetooth-activated-symbolic" : "preferences-system-bluetooth-inactive-symbolic")
  }
}
