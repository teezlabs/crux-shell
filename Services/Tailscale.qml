pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Tailscale state from `tailscale status --json`, sampled only while something watches (the Control Center).
Singleton {
  id: root

  property int watchers: 0
  property bool available: false
  property bool running: false
  property bool busy: false
  property string ip: ""
  property string exitNode: ""
  property int peersOnline: 0
  property int peersTotal: 0

  function refresh(): void {
    if (!statusProc.running)
      statusProc.running = true;
  }

  // Needs `tailscale set --operator=$USER` once; without it the CLI refuses and the state stays as it was.
  function toggle(): void {
    if (root.busy || !root.available)
      return;
    root.busy = true;
    toggleProc.command = ["tailscale", root.running ? "down" : "up"];
    toggleProc.running = true;
  }

  Timer {
    interval: 5000
    running: root.watchers > 0
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProc
    command: ["tailscale", "status", "--json"]
    stdout: StdioCollector {
      id: statusOut
      waitForEnd: true
    }
    onExited: exitCode => {
      try {
        const d = JSON.parse(statusOut.text);
        root.available = true;
        root.running = d.BackendState === "Running";
        root.ip = d.Self && d.Self.TailscaleIPs ? d.Self.TailscaleIPs[0] : "";
        const peers = Object.values(d.Peer || {});
        root.peersTotal = peers.length;
        root.peersOnline = peers.filter(p => p.Online).length;
        const exitId = d.ExitNodeStatus ? d.ExitNodeStatus.ID : "";
        const exit = exitId ? peers.find(p => p.ID === exitId) : null;
        root.exitNode = exit ? exit.HostName : "";
      } catch (e) {
        root.available = false;
        root.running = false;
      }
    }
  }

  Process {
    id: toggleProc
    stderr: StdioCollector {
      id: toggleErr
      waitForEnd: true
    }
    onExited: exitCode => {
      root.busy = false;
      if (exitCode !== 0)
        console.warn("tailscale:", toggleErr.text.trim());
      root.refresh();
    }
  }
}
