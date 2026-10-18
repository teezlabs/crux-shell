pragma Singleton

import QtQuick
import Quickshell

// Installed font families for the font pickers. Monospace means 'i' and 'W' advance identically; computed once, lazily.
Singleton {
  id: root

  readonly property var families: Qt.fontFamilies()

  property var monoFamilies: []
  property bool monoReady: false

  function ensureMono(): void {
    if (root.monoReady)
      return;
    const out = [];
    for (const fam of root.families) {
      probe.font.family = fam;
      if (Math.abs(probe.advanceWidth("i") - probe.advanceWidth("W")) < 0.01)
        out.push(fam);
    }
    root.monoFamilies = out;
    root.monoReady = true;
  }

  readonly property FontMetrics probe: FontMetrics {
    font.pixelSize: 32
  }
}
