import QtQuick
import Quickshell.Services.UPower
import qs.Commons
import qs.Modules.ControlCenter
import qs.Services

// Power profile tile: cycles saver -> balanced -> performance; unavailable without power-profiles-daemon.
CcTile {
  id: tile
  signal expandRequested(string which)

  readonly property int profile: PowerProfileService.profile

  symbol: tile.profile === PowerProfile.Performance ? "bolt" : tile.profile === PowerProfile.PowerSaver ? "eco" : "balance"
  label: "Power profile"
  status: !PowerProfileService.available ? "Unavailable" : tile.profile === PowerProfile.Performance ? "Performance" : tile.profile === PowerProfile.PowerSaver ? "Power saver" : "Balanced"
  available: PowerProfileService.available
  active: PowerProfileService.available && tile.profile !== PowerProfile.Balanced
  onTapped: PowerProfileService.cycle()
}
