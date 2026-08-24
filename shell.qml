// crux shell — boot smoke test. Launch with `qs -c crux`.

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Modules.Background
import qs.Modules.Bar
import qs.Modules.OSD
import qs.Modules.Polkit
// Not instantiated here — SettingsWindow is opened by the dynamically
// Loader-loaded Settings.qml bar widget, which can't resolve a qs.Modules.*
// module on its own. Statically importing it once here registers it with
// the engine so the dynamic loader's own `import qs.Modules.SettingsPanel`
// resolves. See crux skill for the full gotcha writeup.
import qs.Modules.SettingsPanel

ShellRoot {
  PolkitAgent {}

  Background {}

  IpcHandler {
    target: "wallpaper"
    function set(path: string): void {
      Settings.data.wallpaper.path = path;
    }
  }

  // Backs both the physical volume keys (see keybinds.lua) and anything
  // else that wants to nudge the default sink without going through the
  // Sound popup's own UI — same Pipewire read/write pattern as
  // Modules/Bar/Widgets/Sound.qml and Modules/OSD/VolumeOsd.qml.
  IpcHandler {
    target: "volume"
    function increase(): void {
      var sink = Pipewire.ready ? Pipewire.defaultAudioSink : null;
      if (!sink || !sink.audio)
        return;
      sink.audio.muted = false;
      sink.audio.volume = Math.min(1, sink.audio.volume + 0.05);
    }
    function decrease(): void {
      var sink = Pipewire.ready ? Pipewire.defaultAudioSink : null;
      if (!sink || !sink.audio)
        return;
      sink.audio.volume = Math.max(0, sink.audio.volume - 0.05);
    }
    function muteOutput(): void {
      var sink = Pipewire.ready ? Pipewire.defaultAudioSink : null;
      if (!sink || !sink.audio)
        return;
      sink.audio.muted = !sink.audio.muted;
    }
  }

  // Receives live wallpaper-derived colors from aurora-wallpaper-theme
  // (matugen -> hue-anchored ANSI colors.toml text -> here), the same
  // "shell.applyTheme(colorsB64, shellB64)" IPC contract Omarchy Quattro's
  // shell exposed — colorsB64 is base64-encoded colors.toml *text*, parsed
  // with a lenient line-by-line `key = "value"` scan (shellB64 is unused;
  // Omarchy's version used it for a second embedded shell-vars.sh payload
  // crux has no equivalent for). See crux skill's "Wallpaper + theming"
  // section for the full pipeline this feeds.
  IpcHandler {
    target: "shell"

    // QML's JS engine has no atob/btoa (those are browser globals, not
    // part of the ECMAScript core Qt's QJSEngine implements) — decode
    // base64 by hand instead.
    function _base64Decode(b64: string): string {
      var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
      var str = b64.replace(/[^A-Za-z0-9+/]/g, "");
      var output = "";
      for (var i = 0; i < str.length; i += 4) {
        var e1 = chars.indexOf(str.charAt(i));
        var e2 = chars.indexOf(str.charAt(i + 1));
        var e3 = chars.indexOf(str.charAt(i + 2));
        var e4 = chars.indexOf(str.charAt(i + 3));
        var c1 = (e1 << 2) | (e2 >> 4);
        var c2 = ((e2 & 15) << 4) | (e3 >> 2);
        var c3 = ((e3 & 3) << 6) | e4;
        output += String.fromCharCode(c1);
        if (e3 !== -1)
          output += String.fromCharCode(c2);
        if (e4 !== -1)
          output += String.fromCharCode(c3);
      }
      return output;
    }

    function applyTheme(colorsB64: string, shellB64: string): void {
      var text = _base64Decode(colorsB64);
      var map = ({});
      var lines = text.split("\n");
      for (var i = 0; i < lines.length; i++) {
        var m = lines[i].match(/^(\w+)\s*=\s*"([^"]*)"/);
        if (m)
          map[m[1]] = m[2];
      }
      var theme = Settings.data.theme;
      if (map.accent)
        theme.mPrimary = map.accent;
      if (map.background) {
        theme.mSurface = map.background;
        theme.mOnPrimary = map.background;
        theme.mOnSecondary = map.background;
        theme.mOnError = map.background;
      }
      if (map.foreground)
        theme.mOnSurface = map.foreground;
      if (map.dark_background)
        theme.mSurfaceVariant = map.dark_background;
      if (map.dark_foreground)
        theme.mOnSurfaceVariant = map.dark_foreground;
      if (map.muted)
        theme.mOutline = map.muted;
      if (map.red) {
        theme.mSecondary = map.red;
        theme.mError = map.red;
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: root
      required property var modelData
      screen: modelData

      readonly property string barPosition: Settings.isLoaded ? Settings.getBarPositionForScreen(screen.name) : "top"
      readonly property bool barIsVertical: barPosition === "left" || barPosition === "right"

      anchors {
        top: barPosition === "top" || barIsVertical
        bottom: barPosition === "bottom" || barIsVertical
        left: barPosition === "left" || !barIsVertical
        right: barPosition === "right" || !barIsVertical
      }
      margins {
        top: Style.marginS
        bottom: Style.marginS
        left: Style.marginS
        right: Style.marginS
      }
      // When vertical, top+bottom anchors fill height and only implicitWidth matters (and vice versa).
      implicitWidth: 32
      implicitHeight: 32
      // Transparent so the margins above actually read as a floating gap
      // around a rounded pill (the Rectangle below), not a plain inset
      // rectangle on a same-colored background.
      color: "transparent"

      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.namespace: "crux-bar"
      WlrLayershell.exclusionMode: ExclusionMode.Auto

      Rectangle {
        anchors.fill: parent
        radius: Style.radiusM
        color: Color.alpha(Color.mSurface, Style.barOpacity)
        border.color: Color.mOutline
        border.width: 1

        Bar {
          screen: root.screen
          vertical: root.barIsVertical
        }
      }

      VolumeOsd {
        targetScreen: root.screen
      }
    }
  }
}
