import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// Bluetooth quick toggle. Tapping expands the device list inline.
CcCircleToggle {
  id: tile
  signal expandRequested(string which)

  readonly property var adapter: Bluetooth.defaultAdapter
  active: !!adapter && adapter.enabled
  available: !!adapter
  onTapped: tile.expandRequested("bluetooth")

  NIcon {
    anchors.centerIn: parent
    width: 16
    height: 16
    iconName: tile.active ? "preferences-system-bluetooth-activated-symbolic" : "preferences-system-bluetooth-inactive-symbolic"
    fallbackIconName: "preferences-system-bluetooth"
    color: tile.active ? Color.primaryText : Color.surfaceText
  }
}
