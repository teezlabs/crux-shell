import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Modules.Bar.Extras

// Standalone Hue popup for the Hue.qml bar widget — window chrome and
// anchoring only; the actual brightness/color control lives in
// HuePanelContent.qml.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  // Anchor beside whichever edge the bar actually occupies instead of a
  // hardcoded screen corner — see the matching comment in
  // SoundMenuWindow.qml for the full reasoning.
  readonly property string _barPos: Settings.isLoaded ? Settings.getBarPositionForScreen(root.targetScreen ? root.targetScreen.name : "") : "top"
  readonly property bool _barLeft: root._barPos === "left"
  readonly property bool _barRight: root._barPos === "right"
  readonly property bool _barBottom: root._barPos === "bottom"
  readonly property bool _barTop: !root._barLeft && !root._barRight && !root._barBottom
  readonly property real _barOffset: Settings.data.bar.thickness + Settings.data.bar.floatMargin

  // Bar-icon trigger position, mapped into this popup's space; -1 = not set (IPC open). See SoundMenuWindow.qml.
  property point triggerPos: Qt.point(-1, -1)
  readonly property bool _hasTrigger: triggerPos.x >= 0
  readonly property real _triggerX: triggerPos.x + Settings.data.bar.floatMargin
  readonly property real _triggerY: triggerPos.y + Settings.data.bar.floatMargin

  visible: false
  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-hue-menu"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  function toggle() {
    visible = !visible;
  }

  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "hue"
    function toggle() {
      root.toggle();
    }
    function open() {
      root.visible = true;
    }
    function close() {
      root.visible = false;
    }
  }

  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.visible = false
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.visible = false
  }

  Item {
    id: card
    // Cross-axis position (along the bar's own length): lines up with the
    // triggering icon when known, clamped on-screen; falls back to the old
    // fixed near-corner inset otherwise. Main-axis position (the gap
    // between the bar and the popup) always uses _barOffset, unchanged.
    readonly property real _crossFallback: 12
    readonly property real _crossPos: {
      if (root._barLeft || root._barRight)
        return root._hasTrigger ? Math.max(8, Math.min(root._triggerY, root.height - card.height - 8)) : _crossFallback;
      return root._hasTrigger ? Math.max(8, Math.min(root._triggerX, root.width - card.width - 8)) : root.width - card.width - _crossFallback;
    }

    x: root._barLeft ? root._barOffset : (root._barRight ? root.width - card.width - root._barOffset : card._crossPos)
    y: root._barBottom ? root.height - card.height - root._barOffset : (root._barLeft || root._barRight ? card._crossPos : root._barOffset)
    width: 300
    height: Math.min(320, content.implicitHeight + 24)

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      // Flush against the bar, so cut only the two corners on the far
      // side from it -- the near side reads as growing out of the bar
      // instead of floating as a fully separate chamfered card.
      cutTopLeft: root._barBottom || root._barRight
      cutTopRight: root._barBottom || root._barLeft
      cutBottomLeft: root._barTop || root._barRight
      cutBottomRight: root._barTop || root._barLeft
      omitStrokeSide: root._barBottom ? "bottom" : (root._barLeft ? "left" : (root._barRight ? "right" : "top"))
      fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
      strokeColor: Color.outline
      strokeWidth: Tokens.borderPanel
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    HuePanelContent {
      id: content
      anchors.fill: parent
      anchors.margins: 14
    }
  }
}
