import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

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

  NIcon {
    anchors.centerIn: parent
    width: 16
    height: 16
    iconName: tile.active ? "audio-input-microphone-symbolic" : "microphone-sensitivity-muted-symbolic"
    fallbackIconName: tile.active ? "audio-input-microphone" : "microphone-sensitivity-muted"
    color: tile.active ? Color.primaryText : Color.surfaceText
  }
}
