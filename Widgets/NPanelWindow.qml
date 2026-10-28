import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons

// Chrome for the full-screen surfaces (launcher, wallpaper browser, settings); children sit above the click-catcher.
// Visible-toggled on purpose: always-mapped needs an input mask (docs/design-notes.md).
PanelWindow {
  id: root

  // Name in the Popups registry, and the stem of the per-screen IPC target.
  property string popupName: ""
  property var targetScreen: null
  // Hyprland's blur rule matches these names, so a new namespace needs adding there too.
  property string surfaceNamespace: "crux-" + root.popupName
  property bool closeOnOutsideClick: true
  // Off while a child surface claims Escape; two enabled Escape shortcuts are ambiguous and neither fires.
  property bool escapeCloses: true

  screen: targetScreen

  function open(): void {
    root.visible = true;
  }
  function close(): void {
    root.visible = false;
  }
  function toggle(): void {
    root.visible = !root.visible;
  }

  // Direct in-process handle for callers on this screen (see Commons/Popups.qml).
  PopupRegistration {
    name: root.popupName
    surface: root
    screen: root.targetScreen
  }

  // "<name>_<screen>" target; the bare alias lives in PopupAliases.
  IpcHandler {
    target: root.popupName + "_" + (root.targetScreen ? root.targetScreen.name : "0")
    function toggle(): void {
      root.toggle();
    }
    function open(): void {
      root.open();
    }
    function close(): void {
      root.close();
    }
    // No-op unless the surface declares openTab.
    function openTab(tab: string): void {
      if (root.openTab)
        root.openTab(tab);
    }
  }

  visible: false
  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: root.surfaceNamespace
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  Shortcut {
    sequence: "Escape"
    enabled: root.visible && root.escapeCloses
    onActivated: root.close()
  }

  // Focus while open, cleared on an outside click on any monitor; an Exclusive layer would swallow those clicks.
  HyprlandFocusGrab {
    active: root.visible
    windows: [root]
    onCleared: Popups.closeAll()
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.closeOnOutsideClick
    onClicked: Popups.closeAll()
  }
}
