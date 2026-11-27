pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons

// Pings the homelab hosts from Settings.data.homelab.hosts while something watches (the Control Center).
Singleton {
  id: root

  property int watchers: 0
  // [{name, address}] from "name=address" entries.
  readonly property var hosts: {
    if (!Settings.isLoaded)
      return [];
    const out = [];
    for (const entry of Settings.data.homelab.hosts) {
      const at = entry.indexOf("=");
      if (at > 0)
        out.push({
          "name": entry.slice(0, at).trim(),
          "address": entry.slice(at + 1).trim()
        });
    }
    return out;
  }
  // name -> {up, ms}; a host missing here hasn't been checked yet.
  property var status: ({})
  readonly property int upCount: root.hosts.filter(h => root.status[h.name] && root.status[h.name].up).length

  function check(): void {
    if (checkProc.running || root.hosts.length === 0)
      return;
    const args = [];
    for (const h of root.hosts)
      args.push(h.name, h.address);
    checkProc.command = ["sh", "-c", "while [ $# -gt 1 ]; do n=$1 a=$2; shift 2; (if out=$(ping -c1 -W1 -- \"$a\" 2>/dev/null); then echo \"$n 1 $(printf '%s' \"$out\" | sed -n 's/.*time=\\([0-9.]*\\).*/\\1/p')\"; else echo \"$n 0\"; fi) & done; wait", "sh"].concat(args);
    checkProc.running = true;
  }

  onHostsChanged: root.status = ({})

  Timer {
    interval: 30000
    running: root.watchers > 0 && root.hosts.length > 0
    repeat: true
    triggeredOnStart: true
    onTriggered: root.check()
  }

  Process {
    id: checkProc
    stdout: StdioCollector {
      id: checkOut
      waitForEnd: true
    }
    onExited: exitCode => {
      const next = {};
      for (const line of checkOut.text.split("\n")) {
        const parts = line.trim().split(" ");
        if (parts.length >= 2)
          next[parts[0]] = {
            "up": parts[1] === "1",
            "ms": parts.length > 2 && parts[2] !== "" ? Math.round(parseFloat(parts[2])) : -1
          };
      }
      root.status = next;
    }
  }
}
