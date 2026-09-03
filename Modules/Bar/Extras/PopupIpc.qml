import QtQuick
import Quickshell.Io

// The per-screen IPC target a PopupHost card exposes:
// "<name>_<screen>" always resolves to this screen's own instance — what a
// bar icon calls, since it already knows which screen it's on and where
// the icon sits. The screen-agnostic "<name>" alias is owned by
// PopupAliases, once for the whole shell rather than once per monitor.
QtObject {
  id: root

  required property var host // PopupHost's PanelWindow
  required property var card // the SlideCard this drives

  readonly property string screenName: root.host && root.host.targetScreen ? root.host.targetScreen.name : "0"

  readonly property IpcHandler perScreen: IpcHandler {
    target: root.card.popupName + "_" + root.screenName
    function toggle(): void {
      root.card.toggle();
    }
    function open(): void {
      root.card.open();
    }
    function openAt(x: real, y: real): void {
      root.card.openAt(x, y);
    }
    function close(): void {
      root.card.close();
    }
  }
}
