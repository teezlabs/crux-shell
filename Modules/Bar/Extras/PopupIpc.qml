import QtQuick
import Quickshell.Io
import Quickshell.Hyprland

// The two IPC targets every PopupHost card exposes, from one declaration.
//
// "<name>_<screen>" always resolves to this screen's own instance — what a
// bar icon calls, since it already knows which screen it's on and where
// the icon sits. Plain "<name>" is the screen-agnostic alias for keybinds;
// only the instance on the focused monitor claims it, because every popup
// exists once per monitor and duplicate targets are silently dropped (see
// the crux skill's IPC section).
QtObject {
  id: root

  required property var host // PopupHost's PanelWindow
  required property var card // the SlideCard this drives

  readonly property string screenName: root.host && root.host.targetScreen ? root.host.targetScreen.name : "0"
  readonly property bool onFocusedMonitor: root.host && root.host.targetScreen && Hyprland.focusedMonitor && root.host.targetScreen.name === Hyprland.focusedMonitor.name

  readonly property IpcHandler perScreen: IpcHandler {
    target: root.card.popupName + "_" + root.screenName
    function toggle(): void {
      root.card.toggle();
    }
    function open(): void {
      root.card.open = true;
    }
    function openAt(x: real, y: real): void {
      root.card.openAt(x, y);
    }
    function close(): void {
      root.card.open = false;
    }
  }

  readonly property IpcHandler focusedAlias: IpcHandler {
    enabled: root.onFocusedMonitor
    target: root.card.popupName
    function toggle(): void {
      root.card.toggle();
    }
    function open(): void {
      root.card.open = true;
    }
    function close(): void {
      root.card.open = false;
    }
  }
}
