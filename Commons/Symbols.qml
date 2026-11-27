pragma Singleton

import QtQuick
import Quickshell
import "SymbolCodepoints.js" as Codepoints

// Material Symbols Rounded, bundled and subset in Assets/Fonts (packaging/subset-symbols.py adds icons).
Singleton {
  id: root

  readonly property string family: loader.status === FontLoader.Ready ? loader.name : ""

  function glyph(name: string): string {
    const cp = Codepoints.map[name];
    return cp === undefined ? "" : String.fromCodePoint(cp);
  }

  readonly property FontLoader loader: FontLoader {
    source: Qt.resolvedUrl("../Assets/Fonts/MaterialSymbolsRounded.ttf")
  }
}
