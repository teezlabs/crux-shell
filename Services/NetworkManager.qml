pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// NetworkManager connection profiles and wired devices from nmcli, refreshed on `nmcli monitor` events.
Singleton {
  id: root

  // {name, uuid, type, device, active, autoconnect, priority}
  property var connections: []
  readonly property var vpnConnections: connections.filter(c => c.type === "vpn" || c.type === "wireguard")
  readonly property var activeVpn: vpnConnections.find(c => c.active) || null
  readonly property var wifiConnections: connections.filter(c => c.type === "802-11-wireless")

  property bool ethernetPresent: false
  property bool ethernetConnected: false
  property string ethernetDevice: ""

  property bool busy: false

  function refresh(): void {
    if (!connectionsProc.running)
      connectionsProc.running = true;
    if (!devicesProc.running)
      devicesProc.running = true;
  }

  function setVpn(uuid: string, up: bool): void {
    run(["nmcli", "connection", up ? "up" : "down", "uuid", uuid]);
  }

  function toggleVpn(): void {
    if (busy)
      return;
    if (activeVpn)
      setVpn(activeVpn.uuid, false);
    else if (vpnConnections.length > 0)
      setVpn(vpnConnections[0].uuid, true);
  }

  function setAutoconnect(uuid: string, enabled: bool): void {
    run(["nmcli", "connection", "modify", "uuid", uuid, "connection.autoconnect", enabled ? "yes" : "no"]);
  }

  function setPriority(uuid: string, priority: int): void {
    run(["nmcli", "connection", "modify", "uuid", uuid, "connection.autoconnect-priority", String(priority)]);
  }

  function forget(uuid: string): void {
    run(["nmcli", "connection", "delete", "uuid", uuid]);
  }

  // While a command runs, only the latest one queued after it is kept (slider drags send many).
  property var _pending: null

  function run(command: var): void {
    if (actionProc.running) {
      _pending = command;
      return;
    }
    busy = true;
    actionProc.command = command;
    actionProc.running = true;
  }

  // Splits an `nmcli -t` line on unescaped colons and unescapes `\:` and `\\` in each field.
  function splitTerse(line: string): var {
    var fields = [];
    var cur = "";
    for (var i = 0; i < line.length; i++) {
      var ch = line[i];
      if (ch === "\\" && i + 1 < line.length) {
        cur += line[++i];
      } else if (ch === ":") {
        fields.push(cur);
        cur = "";
      } else {
        cur += ch;
      }
    }
    fields.push(cur);
    return fields;
  }

  Component.onCompleted: refresh()

  readonly property Timer debounce: Timer {
    interval: 250
    onTriggered: root.refresh()
  }

  readonly property Process monitorProc: Process {
    command: ["nmcli", "monitor"]
    running: true
    stdout: SplitParser {
      onRead: root.debounce.restart()
    }
  }

  readonly property Process actionProc: Process {
    onExited: {
      root.busy = false;
      if (root._pending) {
        var next = root._pending;
        root._pending = null;
        root.run(next);
      }
      root.refresh();
    }
  }

  readonly property Process connectionsProc: Process {
    command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,DEVICE,AUTOCONNECT,AUTOCONNECT-PRIORITY", "connection", "show"]
    stdout: StdioCollector {
      onStreamFinished: {
        var rows = [];
        for (const line of text.split("\n")) {
          var f = root.splitTerse(line);
          if (f.length < 6 || !f[1])
            continue;
          rows.push({
            "name": f[0],
            "uuid": f[1],
            "type": f[2],
            "device": f[3],
            "active": !!f[3] && f[3] !== "--",
            "autoconnect": f[4] === "yes",
            "priority": parseInt(f[5]) || 0
          });
        }
        root.connections = rows;
      }
    }
  }

  readonly property Process devicesProc: Process {
    command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]
    stdout: StdioCollector {
      onStreamFinished: {
        var present = false;
        var device = "";
        for (const line of text.split("\n")) {
          var f = root.splitTerse(line);
          if (f.length < 3 || f[1] !== "ethernet")
            continue;
          present = true;
          if (!device && f[2].startsWith("connected"))
            device = f[0];
        }
        root.ethernetPresent = present;
        root.ethernetConnected = device !== "";
        root.ethernetDevice = device;
      }
    }
  }
}
