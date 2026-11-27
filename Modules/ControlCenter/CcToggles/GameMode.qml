import QtQuick
import qs.Commons
import qs.Modules.ControlCenter
import qs.Services

// Game mode tile: Hyprland effects off and the performance profile on, all restored on the next tap.
CcTile {
  id: tile
  signal expandRequested(string which)

  symbol: "sports_esports"
  label: "Game mode"
  status: GameMode.busy ? "Starting…" : tile.active ? "Performance" : "Off"
  active: GameMode.active
  onTapped: GameMode.toggle()
}
