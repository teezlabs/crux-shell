import QtQuick
import qs.Commons
import qs.Modules.ControlCenter

// Do not disturb tile: silences notification toasts; history still records them.
CcTile {
  id: tile
  signal expandRequested(string which)

  symbol: tile.active ? "do_not_disturb_on" : "notifications"
  label: CcToggleRegistry.labelFor("DoNotDisturb")
  status: tile.active ? "Silenced" : "Off"
  active: Settings.data.notifications.doNotDisturb
  onTapped: Settings.data.notifications.doNotDisturb = !Settings.data.notifications.doNotDisturb
}
