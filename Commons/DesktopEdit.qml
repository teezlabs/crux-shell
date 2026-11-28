pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Desktop widget edit mode: while active, cards drag, snap to the grid and resize; otherwise they're locked.
Singleton {
  id: root

  property bool active: false

  function toggle(): void {
    root.active = !root.active;
  }

  // qs ipc -c crux call desktopWidgets toggleEdit
  IpcHandler {
    target: "desktopWidgets"

    function toggleEdit(): void {
      root.toggle();
    }
    function startEdit(): void {
      root.active = true;
    }
    function stopEdit(): void {
      root.active = false;
    }
  }
}
