import QtQuick
import qs.Commons
import qs.Modules.ControlCenter
import qs.Services

// Tailscale tile: tap runs `tailscale up` or `down`; the status shows the exit node, else this machine's address.
CcTile {
  id: tile
  signal expandRequested(string which)

  symbol: tile.active ? "vpn_lock" : "vpn_key_off"
  label: "Tailscale"
  status: !Tailscale.available ? "Not installed" : Tailscale.busy ? (tile.active ? "Disconnecting…" : "Connecting…") : !tile.active ? "Off" : Tailscale.exitNode !== "" ? "Exit via " + Tailscale.exitNode : Tailscale.ip
  active: Tailscale.running
  available: Tailscale.available

  Component.onCompleted: Tailscale.refresh()
  onTapped: Tailscale.toggle()
}
