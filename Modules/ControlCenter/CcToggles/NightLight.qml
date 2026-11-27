import QtQuick
import qs.Commons
import qs.Modules.ControlCenter
import qs.Services

// Night light tile: off -> scheduled -> forced on -> off.
CcTile {
  id: tile
  signal expandRequested(string which)

  symbol: "nightlight"
  label: "Night light"
  status: !NightLightService.enabled ? "Off" : NightLightService.forced ? "Always on" : "Scheduled"
  active: NightLightService.enabled
  onTapped: NightLightService.cycle()
}
