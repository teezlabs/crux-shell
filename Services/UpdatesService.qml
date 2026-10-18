pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Pending package count: checkupdates (+ yay -Qua when yay exists), polled while an Updates widget exists.
Singleton {
  id: root

  property int updateCount: -1 // -1 = not checked yet
  property bool checking: false
  property bool hasYay: false
  property real nextCheckAt: 0
  property int watchers: 0

  readonly property var cfg: Settings.data.updates
  readonly property string _stampDir: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/crux"
  readonly property string _stampFile: _stampDir + "/update-count-stamp"

  function check(): void {
    if (checking)
      return;
    checking = true;
    nextCheckAt = Date.now() + cfg.intervalMinutes * 60 * 1000;
    if (cfg.customCountCmd) {
      countProc.command = ["sh", "-c", cfg.customCountCmd];
      countProc.running = true;
    } else {
      detectProc.running = true;
    }
  }

  // The update runs in a terminal; it touches the stamp file when done so the count rechecks.
  function runUpdate(): void {
    const updateCmd = cfg.customUpdateCmd || (hasYay ? "yay -Syu" : "sudo pacman -Syu");
    const combined = updateCmd + " ; mkdir -p " + _stampDir + " && date +%s%N > " + _stampFile;
    const term = cfg.terminalCommand.trim();
    const fullCmd = term.indexOf("{}") !== -1 ? term.replace("{}", combined) : term + " sh -c \"" + combined.replace(/"/g, "\\\"") + "\"";
    Quickshell.execDetached(["sh", "-c", fullCmd]);
  }

  readonly property Timer poll: Timer {
    interval: root.cfg.intervalMinutes * 60 * 1000
    running: root.watchers > 0
    repeat: true
    triggeredOnStart: true
    onTriggered: root.check()
  }

  readonly property FileView stamp: FileView {
    path: root._stampFile
    printErrors: false
    watchChanges: true
    onFileChanged: {
      reload();
      root.check();
    }
  }

  readonly property IpcHandler ipc: IpcHandler {
    target: "updates"
    function check(): void {
      root.check();
    }
  }

  readonly property Process detectProc: Process {
    command: ["sh", "-c", "command -v yay >/dev/null && echo yay || echo pacman"]
    stdout: StdioCollector {
      id: detectCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      root.hasYay = detectCollector.text.trim() === "yay";
      root.countProc.command = root.hasYay ? ["sh", "-c", "(checkupdates 2>/dev/null; yay -Qua 2>/dev/null) | wc -l"] : ["sh", "-c", "checkupdates 2>/dev/null | wc -l"];
      root.countProc.running = true;
    }
  }

  readonly property Process countProc: Process {
    stdout: StdioCollector {
      id: countCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      const n = parseInt(countCollector.text.trim());
      root.updateCount = isNaN(n) ? 0 : n;
      root.checking = false;
    }
  }
}
