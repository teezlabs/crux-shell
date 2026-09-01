pragma Singleton

import Quickshell
import Quickshell.Io
import qs.Commons

// Wallpaper -> theme color generation via matugen, called directly — parses
// matugen's --json output and writes Settings.data.theme itself, no
// external script dependency.
Singleton {
  id: root

  property bool running: false
  property string lastError: ""

  // Dark-mode variant only — crux has no light/dark concept yet. --type is
  // Settings.data.wallpaper.matugenScheme; --source-color-index picks which
  // dominant color to theme from (see cycleColorIndex) and also skips
  // matugen's interactive disambiguation prompt.
  // System-wide app retheming (Settings.data.wallpaper.templates.*).
  // Every output below is crux-named — Hyprland, kitty, GTK, btop, and
  // yazi's own config files reference these exact filenames (symlink,
  // @import, color_theme=, flavor=), so renaming any of these means
  // updating that consumer too, not just this list.
  readonly property string _templatesDir: Quickshell.shellDir + "/bin/theme-templates/"
  readonly property var _templateDefs: ({
      "hyprland": [
        {
          "input": "hyprland-colors.lua",
          "output": Quickshell.env("HOME") + "/.config/hypr/crux/crux-colors.lua"
        },
        {
          "input": "hyprland-colors.lua",
          "output": Quickshell.env("HOME") + "/.config/hypr/crux.lua"
        }
      ],
      "kitty": [
        {
          "input": "kitty.conf",
          "output": Quickshell.env("HOME") + "/.config/kitty/themes/crux.conf"
        }
      ],
      "gtk": [
        {
          "input": "gtk.css",
          "output": Quickshell.env("HOME") + "/.config/gtk-3.0/crux.css"
        },
        {
          "input": "gtk.css",
          "output": Quickshell.env("HOME") + "/.config/gtk-4.0/crux.css"
        }
      ],
      "qt": [
        {
          "input": "qt6ct-colors.conf",
          "output": Quickshell.env("HOME") + "/.config/qt6ct/colors/crux.conf"
        }
      ],
      "yazi": [
        {
          "input": "yazi-theme.toml",
          "output": Quickshell.env("HOME") + "/.config/yazi/flavors/crux.yazi/flavor.toml"
        }
      ],
      "discord": [
        {
          "input": "vesktop.css",
          "output": Quickshell.env("HOME") + "/.config/vesktop/themes/crux.theme.css"
        }
      ],
      "pywalfox": [
        {
          "input": "pywal-colors.json",
          "output": Quickshell.env("HOME") + "/.cache/wal/colors.json"
        }
      ],
      "btop": [
        {
          "input": "btop-theme.txt",
          "output": Quickshell.env("HOME") + "/.config/btop/themes/crux.theme"
        }
      ],
      // Renders just the palette block to a staging file; bin/crux-splice-
      // starship-palette swaps it into starship.toml between markers.
      "starship": [
        {
          "input": "starship-palette-block.toml",
          "output": Quickshell.env("HOME") + "/.cache/crux/starship-palette-block.toml"
        }
      ]
    })

  function _buildTemplatesToml() {
    var t = Settings.data.wallpaper.templates;
    var lines = ["[config]", "reload_apps = false", ""];
    var n = 0;
    for (var app in root._templateDefs) {
      if (!t[app])
        continue;
      var defs = root._templateDefs[app];
      for (var i = 0; i < defs.length; i++) {
        n++;
        lines.push("[templates.t" + n + "]");
        lines.push("input_path = \"" + root._templatesDir + defs[i].input + "\"");
        lines.push("output_path = \"" + defs[i].output + "\"");
        lines.push("");
      }
    }
    return {
      "toml": lines.join("\n"),
      "count": n
    };
  }

  function _runPostHooks() {
    var t = Settings.data.wallpaper.templates;
    var cmds = [];
    if (t.hyprland)
      cmds.push("hyprctl reload");
    if (t.pywalfox)
      cmds.push("pywalfox update");
    if (t.qt)
      // qt6ct only reads whichever file its own color_scheme_path points
      // at — point it at crux's output once (idempotent, cheap to redo on
      // every regen) rather than requiring a one-time manual qt6ct-gui step.
      cmds.push("sed -i 's|^color_scheme_path=.*|color_scheme_path=" + Quickshell.env("HOME") + "/.config/qt6ct/colors/crux.conf|' " + Quickshell.env("HOME") + "/.config/qt6ct/qt6ct.conf");
    if (t.starship)
      cmds.push(Quickshell.shellDir + "/bin/crux-splice-starship-palette");
    if (t.sddmGreeter)
      cmds.push(Quickshell.shellDir + "/bin/crux-sync-greeter");
    if (t.gsettings)
      cmds.push("gsettings set org.gnome.desktop.interface color-scheme prefer-dark");
    if (cmds.length === 0)
      return;
    postHookProc.command = ["sh", "-c", cmds.join(" ; ")];
    postHookProc.running = true;
  }

  Process {
    id: postHookProc
  }

  property string _pendingImagePath: ""

  function generateFrom(imagePath) {
    if (!imagePath)
      return;
    root.running = true;
    root.lastError = "";
    root._pendingImagePath = imagePath;
    var built = root._buildTemplatesToml();
    if (built.count === 0) {
      root._runMatugen(imagePath, false);
      return;
    }
    // mkdir -p first and only write the config/run matugen once that's
    // done — FileView.setText() and matugen's own template output won't
    // create missing parent directories (yazi's flavors/crux.yazi/,
    // hypr/crux/, etc. may not exist yet on a fresh app).
    mkdirProc._tomlText = built.toml;
    mkdirProc.command = ["sh", "-c", "mkdir -p ~/.cache/crux ~/.config/hypr/crux ~/.config/kitty/themes ~/.config/qt6ct/colors ~/.config/yazi/flavors/crux.yazi ~/.config/vesktop/themes ~/.cache/wal ~/.config/btop/themes"];
    mkdirProc.running = true;
  }

  function _runMatugen(imagePath, withTemplates) {
    var args = ["matugen", "image", imagePath, "--type", Settings.data.wallpaper.matugenScheme, "--mode", "dark", "--json", "hex", "--source-color-index", String(Settings.data.wallpaper.matugenColorIndex)];
    if (withTemplates)
      args = args.concat(["--config", Quickshell.env("HOME") + "/.cache/crux/matugen-templates.toml"]);
    else
      args = args.concat(["--dry-run"]);
    matugenProc.command = args;
    matugenProc.running = true;
  }

  Process {
    id: mkdirProc
    property string _tomlText: ""
    onExited: function (exitCode) {
      templatesConfigView.path = Quickshell.env("HOME") + "/.cache/crux/matugen-templates.toml";
      templatesConfigView.setText(mkdirProc._tomlText);
      root._runMatugen(root._pendingImagePath, true);
    }
  }

  FileView {
    id: templatesConfigView
  }

  // Cycles to the next of an image's 5 candidate dominant colors (0-4,
  // wrapping) and re-runs theme generation on the current wallpaper.
  function cycleColorIndex() {
    Settings.data.wallpaper.matugenColorIndex = (Settings.data.wallpaper.matugenColorIndex + 1) % 5;
    root.generateFrom(Settings.data.wallpaper.path);
  }

  Process {
    id: matugenProc
    stdout: StdioCollector {
      id: stdoutCollector
      waitForEnd: true
    }
    stderr: StdioCollector {
      id: stderrCollector
      waitForEnd: true
    }
    onExited: function (exitCode) {
      root.running = false;
      if (exitCode !== 0) {
        root.lastError = stderrCollector.text || ("matugen exited " + exitCode);
        return;
      }
      try {
        var data = JSON.parse(stdoutCollector.text);
        var c = data.colors;
        var theme = Settings.data.theme;
        theme.mPrimary = c.primary.dark.color;
        theme.mOnPrimary = c.on_primary.dark.color;
        theme.mSecondary = c.secondary.dark.color;
        theme.mOnSecondary = c.on_secondary.dark.color;
        theme.mSurface = c.surface.dark.color;
        theme.mOnSurface = c.on_surface.dark.color;
        theme.mSurfaceVariant = c.surface_variant.dark.color;
        theme.mOnSurfaceVariant = c.on_surface_variant.dark.color;
        theme.mOutline = c.outline.dark.color;
        theme.mError = c.error.dark.color;
        theme.mOnError = c.on_error.dark.color;

        // Tonal-spot roles for the v2 spec (§1) — same JSON response, just
        // more of its fields.
        theme.surface = c.surface.dark.color;
        theme.surfaceContainerLow = c.surface_container_low.dark.color;
        theme.surfaceContainer = c.surface_container.dark.color;
        theme.surfaceContainerHigh = c.surface_container_high.dark.color;
        theme.outline = c.outline.dark.color;
        theme.outlineVariant = c.outline_variant.dark.color;
        theme.primary = c.primary.dark.color;
        theme.primaryContainer = c.primary_container.dark.color;
        theme.primaryContainerText = c.on_primary_container.dark.color;
        theme.tertiary = c.tertiary.dark.color;
        theme.errorTone = c.error.dark.color;
        theme.surfaceText = c.on_surface.dark.color;
        theme.surfaceTextMuted = c.on_surface_variant.dark.color;

        root._runPostHooks();
        Toast.show("Theme updated");
      } catch (e) {
        root.lastError = "Couldn't parse matugen output: " + e;
      }
    }
  }
}
