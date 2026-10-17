pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Hyprland's general:gaps_out, re-read whenever its config reloads.
Singleton {
  id: root

  property int top: 0
  property int right: 0
  property int bottom: 0
  property int left: 0

  function forEdge(edge: string): int {
    return edge === "top" ? top : edge === "right" ? right : edge === "bottom" ? bottom : left;
  }

  function refresh(): void {
    gapsProc.running = true;
  }

  Component.onCompleted: refresh()

  readonly property Connections hyprConn: Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "configreloaded")
        root.refresh();
    }
  }

  readonly property Process gapsProc: Process {
    command: ["hyprctl", "getoption", "general:gaps_out", "-j"]
    stdout: StdioCollector {
      id: gapsCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      try {
        const v = JSON.parse(gapsCollector.text).css.trim().split(/\s+/).map(Number);
        root.top = v[0];
        root.right = v.length > 1 ? v[1] : v[0];
        root.bottom = v.length > 2 ? v[2] : v[0];
        root.left = v.length > 3 ? v[3] : (v.length > 1 ? v[1] : v[0]);
      } catch (e) {}
    }
  }
}
