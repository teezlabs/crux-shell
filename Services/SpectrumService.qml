pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// FFT bands for the default sink, from a cava child process in raw ascii mode.
//
// Capture only runs while something is displaying it: every visualiser
// acquires on becoming visible and releases when it isn't, so a widget that
// scrolled out of view or a closed panel stops the work.
Singleton {
  id: root

  property var values: []
  readonly property int bandCount: root.values.length
  readonly property bool active: root.refCount > 0

  property int refCount: 0

  function acquire(): void {
    root.refCount = root.refCount + 1;
  }

  function release(): void {
    root.refCount = Math.max(0, root.refCount - 1);
  }

  readonly property string config: "[general]\nframerate=60\nbars=32\nautosens=1\n"
                                   + "[input]\nmethod=pipewire\nsource=auto\n"
                                   + "[output]\nmethod=raw\nraw_target=/dev/stdout\ndata_format=ascii\nascii_max_range=100\nbar_delimiter=59\nframe_delimiter=10\n"
                                   + "[smoothing]\nnoise_reduction=60\n"

  Process {
    running: root.refCount > 0
    command: ["setpriv", "--pdeathsig", "TERM", "sh", "-c", "printf '%s' \"$1\" | exec cava -p /dev/stdin", "sh", root.config]
    onRunningChanged: if (!running) root.values = []

    stdout: SplitParser {
      onRead: line => {
        const parts = line.split(";");
        const out = [];
        for (let i = 0; i < parts.length; i++) {
          if (parts[i] !== "")
            out.push(parseInt(parts[i], 10) / 100);
        }
        root.values = out;
      }
    }
  }
}
