pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// FFT bands for the default sink, from Quickshell's own PwAudioSpectrum —
// no cava or other helper process.
//
// Capture only runs while something is displaying it: every visualiser
// acquires on becoming visible and releases when it isn't, so a widget that
// scrolled out of view or a closed panel stops the work.
Singleton {
  id: root

  readonly property var values: spectrum.values || []
  readonly property int bandCount: root.values.length
  readonly property bool active: root.refCount > 0

  property int refCount: 0

  function acquire(): void {
    root.refCount = root.refCount + 1;
  }

  function release(): void {
    root.refCount = Math.max(0, root.refCount - 1);
  }

  readonly property PwAudioSpectrum spectrum: PwAudioSpectrum {
    node: Pipewire.defaultAudioSink
    enabled: root.refCount > 0
  }
}
