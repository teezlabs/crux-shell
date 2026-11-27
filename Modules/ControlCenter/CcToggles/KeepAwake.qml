import QtQuick
import qs.Commons
import qs.Modules.ControlCenter
import qs.Services

// Keep-awake tile, sharing IdleInhibitorService with the bar widget.
CcTile {
  id: tile
  signal expandRequested(string which)

  symbol: "coffee"
  label: "Keep awake"
  status: tile.active ? "Screen stays on" : "Off"
  active: IdleInhibitorService.active
  onTapped: IdleInhibitorService.toggle()
}
