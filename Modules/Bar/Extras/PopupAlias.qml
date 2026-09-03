import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons

// The screen-agnostic IPC target for one popup ("wifi", "settings", ...),
// for keybinds and scripts that don't know or care which monitor they're
// on.
//
// Exactly one of these exists per popup name, and it resolves the focused
// monitor at *call* time through Popups. Each popup used to expose its own
// alias from every per-monitor instance, gated on
// `targetScreen.name === Hyprland.focusedMonitor.name`. On a focus change
// both instances are briefly enabled, they race for the same target name,
// and Quickshell drops the loser with "Handler was registered but will not
// be used" — after which the alias could be bound to the wrong monitor.
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
