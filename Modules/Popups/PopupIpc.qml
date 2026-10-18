import QtQuick
import Quickshell.Io

// The "<name>_<screen>" IPC target for a card; the bare "<name>" alias lives in PopupAliases.
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
