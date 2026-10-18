pragma Singleton

import QtQuick
import Quickshell

// Debounced global tooltip state; one TooltipOverlay per screen draws it.
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

  // item: the Item to anchor to. text: plain string, "\n" allowed for a second line.
  function show(item, str) {
    if (!item || !str) {
      hide();
      return;
    }

    hideTimer.stop();

    // A new target while one is showing drops the bubble and re-arms the delay instead of sliding over.
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

  // No delay, e.g. when a click opens a popup.
  function hideImmediately() {
    showTimer.stop();
    hideTimer.stop();
    visible = false;
    anchorItem = null;
    text = "";
  }
}
