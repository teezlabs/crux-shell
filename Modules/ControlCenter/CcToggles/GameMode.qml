import QtQuick
import qs.Commons
import qs.Modules.ControlCenter
import qs.Services

// Game mode tile: Hyprland effects off and the performance profile on, all restored on the next tap.
CcTile {
  id: tile
  signal expandRequested(string which)

  symbol: "sports_esports"
  label: CcToggleRegistry.labelFor("GameMode")
  status: GameMode.busy ? "Starting…" : tile.active ? "Performance" : "Off"
  active: GameMode.active
  onTapped: GameMode.toggle()
}
