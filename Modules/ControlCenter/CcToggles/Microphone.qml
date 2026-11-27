import QtQuick
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Modules.ControlCenter

// Microphone mute tile.
CcTile {
  id: tile
  signal expandRequested(string which)

  readonly property var source: Pipewire.defaultAudioSource

  symbol: tile.active ? "mic" : "mic_off"
  label: "Microphone"
  status: !tile.source ? "No input" : tile.active ? "On" : "Muted"
  active: !!tile.source && !!tile.source.audio && !tile.source.audio.muted
  available: !!tile.source
  onTapped: {
    if (tile.source && tile.source.audio)
      tile.source.audio.muted = !tile.source.audio.muted;
  }
}
