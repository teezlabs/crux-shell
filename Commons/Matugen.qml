pragma Singleton

import Quickshell
import Quickshell.Io
import qs.Commons

// Wallpaper -> theme color generation via matugen, called directly (no
// intermediate colors.toml/base64/IPC round-trip — that pattern existed in
// an earlier external pipeline built for an Omarchy-shaped shell.applyTheme
// contract; crux's own theme schema already uses Material-You role names
// almost 1:1 with matugen's own --json output, so this parses that JSON
// directly and writes Settings.data.theme itself). Self-contained: crux
// owns its whole wallpaper-to-theme pipeline, no external script dependency.
Singleton {
  id: root

  property bool running: false
  property string lastError: ""

  // Direct role-name mapping — dark-mode variant only, since crux has no
  // light/dark mode concept yet (see Style.qml/Settings.qml: no darkMode
  // toggle exists). Add a light-mode branch here if that ever changes.
  //
  // --type comes from Settings.data.wallpaper.matugenScheme (scheme-fidelity
  // by default — matches noctalia-shell's skwd, and stays close to the
  // wallpaper's own saturation instead of Material 3's deliberately muted
  // scheme-tonal-spot). --source-color-index picks which of an image's
  // dominant candidate colors to theme from (see cycleColorIndex below) —
  // it also skips matugen's interactive disambiguation prompt on its own,
  // so no --prefer flag is needed alongside it.
  // System-wide app retheming (Settings.data.wallpaper.templates.*) —
  // crux's own equivalent of noctalia's Settings > Color Scheme >
  // Templates tab. Reuses the SAME output paths noctalia's own templating
  // already wired into these apps (kitty's current-theme.conf symlink,
  // gtk.css's @import, yazi's flavor = "noctalia") rather than inventing
  // new "crux"-named files that would need fresh manual wiring — since
  // noctalia isn't running any more, crux writing to those same paths is
  // just as valid an owner of them. Two apps beyond a wallpaper.png
  // (Hyprland via a .lua template, pywalfox via a pywal-shaped JSON) don't
  // fit matugen's usual "render text file" model but matugen's templating
  // is just plain-text substitution, so a .lua/.json file works the same
  // as any other template.
  readonly property string _templatesDir: Quickshell.shellDir + "/bin/theme-templates/"
  readonly property var _templateDefs: ({
      "hyprland": [
        {
          "input": "hyprland-colors.lua",
          "output": Quickshell.env("HOME") + "/.config/hypr/noctalia/noctalia-colors.lua"
        },
        {
          "input": "hyprland-colors.lua",
          "output": Quickshell.env("HOME") + "/.config/hypr/noctalia.lua"
        }
      ],
      "kitty": [
        {
          "input": "kitty.conf",
          "output": Quickshell.env("HOME") + "/.config/kitty/themes/noctalia.conf"
        }
      ],
      "gtk": [
        {
          "input": "gtk.css",
          "output": Quickshell.env("HOME") + "/.config/gtk-3.0/noctalia.css"
        },
        {
          "input": "gtk.css",
          "output": Quickshell.env("HOME") + "/.config/gtk-4.0/noctalia.css"
        }
      ],
      "qt": [
        {
          "input": "qt6ct-colors.conf",
          "output": Quickshell.env("HOME") + "/.config/qt6ct/colors/noctalia.conf"
        }
      ],
      "yazi": [
        {
          "input": "yazi-theme.toml",
          "output": Quickshell.env("HOME") + "/.config/yazi/flavors/noctalia.yazi/flavor.toml"
        }
      ],
      "discord": [
        {
          "input": "vesktop.css",
          "output": Quickshell.env("HOME") + "/.config/vesktop/themes/noctalia.theme.css"
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
          "output": Quickshell.env("HOME") + "/.config/btop/themes/noctalia.theme"
        }
      ],
      // starship.toml has real user prompt config alongside its palette —
      // matugen renders just the palette block to a staging file here,
      // then bin/crux-splice-starship-palette (a post-hook) swaps it into
      // starship.toml between marker comments, never touching anything
      // else in that file.
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
      cmds.push("sed -i 's|^color_scheme_path=.*|color_scheme_path=" + Quickshell.env("HOME") + "/.config/qt6ct/colors/noctalia.conf|' " + Quickshell.env("HOME") + "/.config/qt6ct/qt6ct.conf");
    if (t.starship)
      cmds.push(Quickshell.shellDir + "/bin/crux-splice-starship-palette");
    if (t.sddmGreeter)
      cmds.push(Quickshell.shellDir + "/bin/crux-sync-greeter");
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
    // create missing parent directories (yazi's flavors/noctalia.yazi/,
    // hypr/noctalia/, etc. may not exist yet on a fresh app).
    mkdirProc._tomlText = built.toml;
    mkdirProc.command = ["sh", "-c", "mkdir -p ~/.cache/crux ~/.config/hypr/noctalia ~/.config/kitty/themes ~/.config/qt6ct/colors ~/.config/yazi/flavors/noctalia.yazi ~/.config/vesktop/themes ~/.cache/wal ~/.config/btop/themes"];
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
  // wrapping) and re-runs theme generation on the current wallpaper — the
  // same "cycle through different Material You themes on one wallpaper"
  // control noctalia-shell's skwd exposes as matugenColorIndex.
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

        // Also mirror into skwd-wall's own colors.json — the embedded
        // wallpaper selector (Modules/Bar/Extras/skwd, ported from
        // noctalia-shell) reads that file live via its own Colors.qml
        // FileView, so writing it here keeps the picker's own chrome
        // visually in sync with whatever crux itself just generated,
        // instead of drifting from skwd-daemon's separately-tracked colors.
        skwdColorsView.path = Quickshell.env("HOME") + "/.cache/skwd-wall/colors.json";
        skwdColorsView.setText(JSON.stringify({
          "primary": c.primary.dark.color,
          "primaryText": c.on_primary.dark.color,
          "primaryContainer": c.primary_container.dark.color,
          "primaryContainerText": c.on_primary_container.dark.color,
          "onPrimary": c.on_primary.dark.color,
          "secondary": c.secondary.dark.color,
          "secondaryText": c.on_secondary.dark.color,
          "secondaryContainer": c.secondary_container.dark.color,
          "secondaryContainerText": c.on_secondary_container.dark.color,
          "tertiary": c.tertiary.dark.color,
          "tertiaryText": c.on_tertiary.dark.color,
          "tertiaryContainer": c.tertiary_container.dark.color,
          "tertiaryContainerText": c.on_tertiary_container.dark.color,
          "background": c.background.dark.color,
          "backgroundText": c.on_background.dark.color,
          "surface": c.surface.dark.color,
          "surfaceText": c.on_surface.dark.color,
          "surfaceVariant": c.surface_variant.dark.color,
          "surfaceVariantText": c.on_surface_variant.dark.color,
          "surfaceContainer": c.surface_container.dark.color,
          "outline": c.outline.dark.color,
          "shadow": c.shadow.dark.color,
          "inverseSurface": c.inverse_surface.dark.color,
          "inverseSurfaceText": c.inverse_on_surface.dark.color,
          "inversePrimary": c.inverse_primary.dark.color,
          "error": c.error.dark.color,
          "errorText": c.on_error.dark.color,
          "errorContainer": c.error_container.dark.color,
          "errorContainerText": c.on_error_container.dark.color
        }, null, 2));

        root._runPostHooks();
        Toast.show("Theme updated");
      } catch (e) {
        root.lastError = "Couldn't parse matugen output: " + e;
      }
    }
  }

  FileView {
    id: skwdColorsView
  }
}
