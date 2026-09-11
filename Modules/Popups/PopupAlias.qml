import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons

// The screen-agnostic IPC target for one popup, declared once for the whole
// shell rather than per monitor — see the crux skill's notes.md.
QtObject {
  id: root

  required property string name

  readonly property string focusedScreen: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""

  readonly property IpcHandler handler: IpcHandler {
    target: root.name
    function toggle(): void {
      Popups.toggle(root.name, root.focusedScreen);
    }
    function open(): void {
      Popups.open(root.name, root.focusedScreen);
    }
    function close(): void {
      Popups.close(root.name, root.focusedScreen);
    }
    // No-ops on a surface that has no tabs (see Popups.openTab).
    function openTab(tab: string): void {
      Popups.openTab(root.name, root.focusedScreen, tab);
    }
  }
}
