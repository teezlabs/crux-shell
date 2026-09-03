import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.Commons
import qs.Modules.Bar.Extras

// Microphone mute quick toggle.
CcCircleToggle {
  id: tile
  signal expandRequested(string which)

  readonly property var source: Pipewire.defaultAudioSource
  active: !!source && !!source.audio && !source.audio.muted
  available: !!source
  onTapped: {
    if (tile.source && tile.source.audio)
      tile.source.audio.muted = !tile.source.audio.muted;
  }

  IconImage {
    anchors.centerIn: parent
    width: 16
    height: 16
    source: Quickshell.iconPath(tile.active ? "audio-input-microphone-symbolic" : "microphone-sensitivity-muted-symbolic")
  }
}
