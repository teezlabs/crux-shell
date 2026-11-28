pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Colour-scheme presets from Assets/ColorSchemes/*.json, plus themes saved from the theme creator in
// ~/.config/crux/themes/*.json (same format, `custom: true`). All load up front: the picker shows a swatch of each.
Singleton {
  id: root

  readonly property string directory: Quickshell.shellDir + "/Assets/ColorSchemes"
  readonly property string userDirectory: Quickshell.env("HOME") + "/.config/crux/themes"

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

  // File name for a theme name: letters, digits, spaces, dashes and underscores only.
  function fileNameFor(name): string {
    return name.replace(/[^A-Za-z0-9 _-]/g, "").trim();
  }

  // Writes a custom theme (dark palette) and reloads the list.
  function save(name, palette): void {
    const file = root.fileNameFor(name);
    if (file === "") {
      Toast.show("Give the theme a name");
      return;
    }
    const colors = {};
    for (const role of root.roles) {
      if (palette[role] !== undefined)
        colors[role] = palette[role];
    }
    saveProc.command = ["sh", "-c", 'mkdir -p "$1" && printf "%s\n" "$3" > "$1/$2.json"', "sh", root.userDirectory, file, JSON.stringify({
        "name": name.trim(),
        "dark": colors
      }, null, 2)];
    saveProc.running = true;
  }

  function remove(name): void {
    const file = root.fileNameFor(name);
    if (file === "")
      return;
    removeProc.command = ["rm", "-f", root.userDirectory + "/" + file + ".json"];
    removeProc.running = true;
  }

  readonly property Process saveProc: Process {
    onExited: exitCode => {
      if (exitCode === 0)
        root.refresh();
      else
        Toast.show("Couldn't save the theme");
    }
  }
  readonly property Process removeProc: Process {
    onExited: root.refresh()
  }

  Component.onCompleted: root.refresh()

  // One "<name>\t<json>" line per scheme, read in a single process.
  readonly property Process listProc: Process {
    // "<custom 0|1>\t<name>\t<json>" per file.
    command: ["sh", "-c", 'for d in 0 1; do dir="$1"; [ "$d" = 1 ] && dir="$2"; for f in "$dir"/*.json; do [ -e "$f" ] || continue; n=$(basename "$f" .json); printf "%s\\t%s\\t" "$d" "$n"; tr -d "\\n" < "$f"; printf "\\n"; done; done', "sh", root.directory, root.userDirectory]

    stdout: StdioCollector {
      onStreamFinished: {
        const found = [];
        for (const line of text.split("\n")) {
          if (line.trim() === "")
            continue;
          const parts = line.split("\t");
          if (parts.length < 3)
            continue;
          const custom = parts[0] === "1";
          const name = parts[1];
          try {
            const data = JSON.parse(parts.slice(2).join("\t"));
            found.push({
              "name": data.name || name,
              "colors": data.dark || {},
              "custom": custom
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
