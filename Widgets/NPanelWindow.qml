import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons

// Shared chrome for crux's full-screen popup surfaces — the launcher,
// wallpaper browser and settings panel. Bar-flush popups don't use this:
// they're SlideCards inside PopupHost, which can animate a close because it
// stays mapped. See the crux skill's notes.md.
//
// Content goes in as plain children; they're appended after this file's own
// click-catcher, so they sit above it and a click on the content doesn't
// dismiss the window.
//
// Stays visible-toggled on purpose. An always-mapped layer-shell surface
// claims pointer input across its entire geometry no matter what any
// internal `enabled` binding says, and needs an explicit empty Region mask
// to become click-through — that's PopupHost's problem to solve, not this
// one's. Don't make this always-mapped.
PanelWindow {
  id: root

  // Name in the Popups registry, and the stem of the per-screen IPC target.
  property string popupName: ""
  property var targetScreen: null
  // Layer-shell namespace. Hyprland's blur rule in windowrules.lua matches
  // on these by name, so a new one has to be added there too or the panel
  // renders unblurred.
  property string surfaceNamespace: "crux-" + root.popupName
  property bool closeOnOutsideClick: true

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

  // "<name>_<screen>" reaches this screen's instance specifically. The
  // screen-agnostic "<name>" alias is owned by PopupAliases, once for the
  // whole shell rather than once per monitor.
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
    // No-ops unless the surface declares its own openTab — reading an
    // undeclared QML property returns undefined rather than throwing.
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
    enabled: root.visible
    onActivated: root.close()
  }

  // Keyboard focus while open, and `cleared` on a click outside on any monitor; an
  // Exclusive layer would swallow clicks on the other monitors instead.
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
