pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Colour-scheme presets from Assets/ColorSchemes/*.json; all load up front because the picker shows a swatch of each.
Singleton {
  id: root

  readonly property string directory: Quickshell.shellDir + "/Assets/ColorSchemes"

  // [{name, colors}], sorted by name.
  property var schemes: []
  property bool loaded: false

  readonly property var roles: ["surface", "surfaceContainerLow", "surfaceContainer", "surfaceContainerHigh", "outline", "outlineVariant", "primary", "primaryContainer", "primaryContainerText", "tertiary", "errorTone", "surfaceText", "surfaceTextMuted", "primaryText", "errorText"]

  function refresh(): void {
    listProc.running = true;
  }

  function apply(name): void {
    for (const s of root.schemes) {
      if (s.name === name) {
        root.applyPalette(s.name, s.colors);
        return;
      }
    }
    Toast.show("No scheme named " + name);
  }

  // Unknown keys are ignored, so a malformed file can't inject junk into the theme.
  function applyPalette(name, palette): void {
    const theme = Settings.data.theme;
    let applied = 0;
    for (const role of root.roles) {
      if (palette[role] !== undefined) {
        theme[role] = palette[role];
        applied++;
      }
    }
    if (applied === 0) {
      Toast.show("Scheme " + name + " has no usable colors");
      return;
    }
    // Older scheme files carry no text-on-fill roles; their dark surface reads on a light primary.
    if (palette.primaryText === undefined && palette.surface !== undefined)
      theme.primaryText = palette.surface;
    if (palette.errorText === undefined && palette.surface !== undefined)
      theme.errorText = palette.surface;
    theme.colorScheme = name;
    Toast.show(name + " applied");
  }

  Component.onCompleted: root.refresh()

  // One "<name>\t<json>" line per scheme, read in a single process.
  readonly property Process listProc: Process {
    command: ["sh", "-c", 'for f in "$1"/*.json; do [ -e "$f" ] || continue; n=$(basename "$f" .json); printf "%s\\t" "$n"; tr -d "\\n" < "$f"; printf "\\n"; done', "sh", root.directory]

    stdout: StdioCollector {
      onStreamFinished: {
        const found = [];
        for (const line of text.split("\n")) {
          if (line.trim() === "")
            continue;
          const tab = line.indexOf("\t");
          if (tab < 0)
            continue;
          const name = line.substring(0, tab);
          try {
            const data = JSON.parse(line.substring(tab + 1));
            found.push({
              "name": data.name || name,
              "colors": data.dark || {}
            });
          } catch (e) {
            console.warn("crux: unreadable color scheme", name);
          }
        }
        found.sort((a, b) => a.name.localeCompare(b.name));
        root.schemes = found;
        root.loaded = true;
      }
    }
  }
}
