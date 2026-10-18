pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Feeds cliphist from one pair of wl-paste watchers; pdeathsig stops them when crux dies, even on SIGKILL.
Singleton {
  id: root

  property bool available: false

  function init(): void {
    checkProc.running = true;
  }

  readonly property Process checkProc: Process {
    command: ["sh", "-c", "command -v cliphist"]
    onExited: exitCode => root.available = exitCode === 0
  }

  readonly property Process watchText: Process {
    command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "text", "--watch", "cliphist", "store"]
    running: root.available
    onExited: textRestart.restart()
  }

  readonly property Process watchImage: Process {
    command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "image", "--watch", "cliphist", "store"]
    running: root.available
    onExited: imageRestart.restart()
  }

  readonly property Timer textRestart: Timer {
    interval: 1000
    onTriggered: if (root.available)
      root.watchText.running = true
  }

  readonly property Timer imageRestart: Timer {
    interval: 1000
    onTriggered: if (root.available)
      root.watchImage.running = true
  }
}
