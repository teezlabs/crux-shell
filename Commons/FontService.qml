pragma Singleton

import QtQuick
import Quickshell

// Installed font families, for the settings panel's font pickers.
//
// Monospace detection is a width comparison rather than any font metadata:
// Qt exposes no "is fixed pitch" flag through QML, but a monospaced face
// advances 'i' and 'W' identically. Computed once, on first use — it walks
// every family, which is ~600 of them here.
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
