pragma Singleton

import QtQuick
import Quickshell

// Global hover-tooltip state (debounced show/hide) — holds no visual state
// itself. TooltipOverlay.qml (one per screen) watches and draws it.
Singleton {
  id: root

  readonly property int showDelay: 400
  readonly property int hideDelay: 80

  property var anchorItem: null
  property string text: ""
  property bool visible: false

  Timer {
    id: showTimer
    interval: root.showDelay
    onTriggered: root.visible = true
  }

  Timer {
    id: hideTimer
    interval: root.hideDelay
    onTriggered: {
      root.visible = false;
      root.anchorItem = null;
      root.text = "";
    }
  }

  // item: the hovered Item to anchor the bubble to (its position/size are
  // read by the overlay every time it repositions). text: plain string,
  // "\n" allowed for a second line.
  function show(item, str) {
    if (!item || !str) {
      hide();
      return;
    }

    hideTimer.stop();

    // Switching to a different target while a tooltip is already
    // showing: drop it immediately and re-arm the show delay, rather
    // than sliding the old bubble over to the new target.
    if (root.visible && root.anchorItem !== item) {
      root.visible = false;
    }

    root.anchorItem = item;
    root.text = str;

    if (!root.visible)
      showTimer.start();
  }

  function hide() {
    showTimer.stop();
    hideTimer.start();
  }

  // Quick hide with no delay — for cases like the widget being clicked
  // (opening a popup) where lingering the tooltip a beat looks wrong.
  function hideImmediately() {
    showTimer.stop();
    hideTimer.stop();
    visible = false;
    anchorItem = null;
    text = "";
  }
}
