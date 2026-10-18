pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons

// Keyboards from `hyprctl devices -j`: active layout and lock-key state of the tracked device.
Singleton {
  id: root

  property var keyboards: []
  readonly property var device: {
    var wanted = Settings.data.keyboard.deviceName;
    var found = keyboards.find(k => wanted && k.name === wanted) || keyboards.find(k => k.main) || keyboards[0];
    return found || null;
  }
  readonly property string deviceName: device ? device.name || "" : ""
  readonly property string layoutName: device ? device.active_keymap || "" : ""
  readonly property string layoutCode: shortCode(layoutName)
  readonly property bool capsLock: device ? !!device.capsLock : false
  readonly property bool numLock: device ? !!device.numLock : false

  // Lock keys emit no Hyprland event, so devices are polled while a LockKeys widget exists.
  property int lockKeyWatchers: 0
  property string _raw: ""

  function refresh(): void {
    if (!devicesProc.running)
      devicesProc.running = true;
  }

  function nextLayout(): void {
    if (!deviceName)
      return;
    Quickshell.execDetached(["hyprctl", "switchxkblayout", deviceName, "next"]);
  }

  function shortCode(layout: string): string {
    if (!layout)
      return "--";
    var str = layout.trim();
    // "English (US)" -> "US"
    var m = str.match(/\(([a-zA-Z]{2,3})\)/);
    if (m)
      return m[1].toUpperCase();
    if (/^[a-zA-Z]{2,3}(\+.*)?$/.test(str))
      return str.split("+")[0].toUpperCase();
    var word = str.split(/[\s(]/)[0];
    return (word.substring(0, 2) || "--").toUpperCase();
  }

  Component.onCompleted: refresh()

  readonly property Connections hyprConn: Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "activelayout" || event.name === "configreloaded")
        root.refresh();
    }
  }

  readonly property Timer lockKeyPoll: Timer {
    interval: 500
    running: root.lockKeyWatchers > 0
    repeat: true
    onTriggered: root.refresh()
  }

  readonly property Process devicesProc: Process {
    command: ["hyprctl", "-j", "devices"]
    stdout: StdioCollector {
      onStreamFinished: {
        if (text === root._raw)
          return;
        root._raw = text;
        try {
          root.keyboards = JSON.parse(text).keyboards || [];
        } catch (e) {}
      }
    }
  }
}
