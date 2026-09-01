import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Modules.Bar.Extras

// One of these is instantiated per screen (see shell.qml's per-screen
// Variants loop, alongside VolumeOsd) and just renders whatever
// TooltipService currently says to show. Full-screen, transparent,
// click-through (mask: Region {} — same trick VolumeOsd.qml/ToastOverlay.qml
// use so a display-only overlay never steals a click meant for something
// under it), so this can sit above the bar without breaking any widget's
// own hover/tap handling.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  // Only actually show on the screen the hovered item is physically on —
  // TooltipService itself is screen-agnostic, it just remembers "which
  // item, what text". mapToGlobal() plus a containment check against
  // this window's own screen picks the right screen's coordinate space.
  readonly property var _anchorItem: TooltipService.anchorItem
  readonly property point _anchorGlobal: _anchorItem ? _anchorItem.mapToGlobal(0, 0) : Qt.point(0, 0)
  readonly property bool _onThisScreen: _anchorItem !== null && targetScreen !== null && _anchorGlobal.x >= targetScreen.x && _anchorGlobal.x < targetScreen.x + targetScreen.width && _anchorGlobal.y >= targetScreen.y && _anchorGlobal.y < targetScreen.y + targetScreen.height

  visible: TooltipService.visible && _onThisScreen
  color: "transparent"

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  WlrLayershell.namespace: "crux-tooltip"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  // Click-through — tooltips are display-only, never eat a click.
  mask: Region {}

  // Bubble position, computed fresh whenever the hovered item, its
  // geometry, the bubble's own measured size, or the screen changes.
  // Prefers below the item (most bar layouts put widgets near the top or
  // along an edge, so "below" usually has the most room); falls back
  // above when there isn't space; always clamped so the bubble never
  // runs off the screen edge.
  readonly property var _pos: {
    const item = _anchorItem;
    if (!item || !targetScreen)
      return {
        "x": 0,
        "y": 0
      };

    const margin = 8;
    const lx = _anchorGlobal.x - targetScreen.x;
    const ly = _anchorGlobal.y - targetScreen.y;
    const iw = item.width;
    const ih = item.height;
    const bw = bubble.width;
    const bh = bubble.height;
    const sw = targetScreen.width;
    const sh = targetScreen.height;

    const spaceBottom = sh - (ly + ih);
    const spaceTop = ly;

    let x = lx + iw / 2 - bw / 2;
    let y;
    if (spaceBottom >= bh + margin || spaceBottom >= spaceTop) {
      y = ly + ih + margin;
    } else {
      y = ly - bh - margin;
    }

    x = Math.max(margin, Math.min(x, sw - bw - margin));
    y = Math.max(margin, Math.min(y, sh - bh - margin));
    return {
      "x": x,
      "y": y
    };
  }

  Item {
    id: bubble
    readonly property int maxTextWidth: 260
    readonly property int textWidth: Math.min(label.implicitWidth, maxTextWidth)

    x: root._pos.x
    y: root._pos.y
    width: textWidth + 16
    height: label.implicitHeight + 10
    opacity: root.visible ? 1 : 0

    Behavior on opacity {
      NumberAnimation {
        duration: Tokens.durationOsdFade
      }
    }

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferIcon
      cutTopRight: true
      cutBottomLeft: true
      fillColor: Color.alpha(Color.surfaceContainerHigh, Tokens.panelOpacity)
      strokeColor: Color.outlineVariant
      strokeWidth: Tokens.borderModule
    }

    Text {
      id: label
      anchors.centerIn: parent
      text: TooltipService.text
      color: Color.surfaceText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.captionSize
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.WordWrap
      width: bubble.textWidth
    }
  }
}
