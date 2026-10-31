pragma Singleton

import Quickshell
import Quickshell.Io
import qs.Commons

// Wallpaper -> theme colours via matugen's --json output, written straight into Settings.data.theme.
Singleton {
  id: root

  property bool running: false
  property string lastError: ""

  readonly property bool darkMode: Settings.isLoaded ? Settings.data.theme.darkMode : true
  readonly property string variant: root.darkMode ? "dark" : "light"

  // Flips the mode and re-themes from the current wallpaper; says so when there's no wallpaper to regenerate from.
  function setDarkMode(on): void {
    if (!Settings.isLoaded || Settings.data.theme.darkMode === on)
      return;
    Settings.data.theme.darkMode = on;
    // Presets ship a dark palette only, so the switch regenerates from the wallpaper and replaces it.
    const preset = Settings.data.theme.colorScheme;
    if (Settings.data.wallpaper.path !== "") {
      root.generateFrom(Settings.data.wallpaper.path);
      if (preset !== "")
        Toast.show(preset + " is dark-only, switched to wallpaper colors");
    } else {
      Toast.show("Pick a wallpaper to regenerate colors");
    }
  }

  function toggleDarkMode(): void {
    root.setDarkMode(!root.darkMode);
  }

  // --json carries both variants; `variant` picks the half the shell reads, --mode only affects the template files.
  // Template outputs are crux-named files that each app's config references, so renaming one means updating that app too.
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
        },
        {
          "input": "vesktop.css",
          "output": Quickshell.env("HOME") + "/.config/BetterDiscord/themes/crux.theme.css"
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
      // Palette block only; bin/crux-splice-starship-palette splices it into starship.toml.
      "starship": [
        {
          "input": "starship-palette-block.toml",
          "output": Quickshell.env("HOME") + "/.cache/crux/starship-palette-block.toml"
        }
      ],
      // The page's index.js polls colors.css and applies the vars to :root.
      "startpage": [
        {
          "input": "startpage-colors.css",
          "output": Quickshell.env("HOME") + "/Projects/startpage/colors.css"
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
    if (t.kitty)
      cmds.push("pkill -USR1 -x kitty");
    if (t.qt)
      // Point qt6ct at crux's colours on every regen, so no manual qt6ct step is needed.
      cmds.push("sed -i 's|^color_scheme_path=.*|color_scheme_path=" + Quickshell.env("HOME") + "/.config/qt6ct/colors/crux.conf|' " + Quickshell.env("HOME") + "/.config/qt6ct/qt6ct.conf");
    if (t.starship)
      cmds.push(Quickshell.shellDir + "/bin/crux-splice-starship-palette");
    if (t.sddmGreeter)
      cmds.push(Quickshell.shellDir + "/bin/crux-sync-greeter");
    if (t.gsettings)
      cmds.push("gsettings set org.gnome.desktop.interface color-scheme prefer-" + root.variant);
    if (cmds.length === 0)
      return;
    // settings.json is written on a debounce, so hand crux-sync-greeter the live values.
    var theme = Settings.data.theme;
    postHookProc.environment = {
      "CRUX_GREETER_STATE": JSON.stringify({
        "wallpaper": root._pendingImagePath || Settings.data.wallpaper.path,
        "theme": {
          "primary": theme.primary,
          "primaryText": theme.primaryText,
          "surface": theme.surface,
          "surfaceText": theme.surfaceText,
          "surfaceContainerHigh": theme.surfaceContainerHigh,
          "surfaceTextMuted": theme.surfaceTextMuted,
          "outline": theme.outline,
          "errorTone": theme.errorTone,
          "errorText": theme.errorText
        },
        "fontFamily": Settings.data.ui.fontFamily
      })
    };
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
    // Neither FileView.setText() nor matugen creates parent directories, so mkdir first.
    mkdirProc._tomlText = built.toml;
    mkdirProc.command = ["sh", "-c", "mkdir -p ~/.cache/crux ~/.config/hypr/crux ~/.config/kitty/themes ~/.config/qt6ct/colors ~/.config/yazi/flavors/crux.yazi ~/.config/vesktop/themes ~/.config/BetterDiscord/themes ~/.cache/wal ~/.config/btop/themes"];
    mkdirProc.running = true;
  }

  function _runMatugen(imagePath, withTemplates) {
    var args = ["matugen", "image", imagePath, "--type", Settings.data.wallpaper.matugenScheme, "--mode", root.variant, "--json", "hex", "--source-color-index", String(Settings.data.wallpaper.matugenColorIndex)];
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

  // Cycles through the image's 5 candidate colours and re-themes.
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
        // Tonal-spot roles for the v2 spec (§1).
        theme.surface = c.surface[root.variant].color;
        theme.surfaceContainerLow = c.surface_container_low[root.variant].color;
        theme.surfaceContainer = c.surface_container[root.variant].color;
        theme.surfaceContainerHigh = c.surface_container_high[root.variant].color;
        theme.outline = c.outline[root.variant].color;
        theme.outlineVariant = c.outline_variant[root.variant].color;
        theme.primary = c.primary[root.variant].color;
        theme.primaryContainer = c.primary_container[root.variant].color;
        theme.primaryContainerText = c.on_primary_container[root.variant].color;
        theme.tertiary = c.tertiary[root.variant].color;
        theme.errorTone = c.error[root.variant].color;
        theme.surfaceText = c.on_surface[root.variant].color;
        theme.surfaceTextMuted = c.on_surface_variant[root.variant].color;
        theme.primaryText = c.on_primary[root.variant].color;
        theme.errorText = c.on_error[root.variant].color;

        // Wallpaper colors replace whatever preset was applied.
        theme.colorScheme = "";

        root._runPostHooks();
        Hooks.runColorGenerationHook();
        Toast.show("Theme updated");
      } catch (e) {
        root.lastError = "Couldn't parse matugen output: " + e;
      }
    }
  }
}
