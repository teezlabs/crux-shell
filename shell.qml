//@ pragma UseQApplication
// crux shell — boot smoke test. Launch with `qs -c crux`.
//
// UseQApplication is required for QsMenuAnchor.open() (Tray.qml's real
// right-click DBusMenu popups) — without it, Quickshell starts in
// QGuiApplication mode and every QsMenuAnchor.open() call fails outright
// with "quickshell was not started in QApplication mode" (confirmed via
// boot log: this was silently breaking every tray right-click).

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Modules.Background
import qs.Modules.Bar
import qs.Modules.Bar.Extras
import qs.Modules.LockScreen
import qs.Modules.OSD
import qs.Modules.Polkit
import qs.Modules.Tooltip
// Not instantiated here — SettingsWindow is opened by the dynamically
// Loader-loaded Settings.qml bar widget, which can't resolve a qs.Modules.*
// module on its own. Statically importing it once here registers it with
// the engine so the dynamic loader's own `import qs.Modules.SettingsPanel`
// resolves. See crux skill for the full gotcha writeup.
import qs.Modules.SettingsPanel
import qs.Modules.SettingsPanel.Controls

ShellRoot {
  PolkitAgent {}

  Background {}

  DesktopWidgets {}

  ToastOverlay {}

  LockScreen {}

  // Crux's own fullscreen wallpaper browser — one instance per screen (see
  // WallpaperSelectorWindow.qml), each with its own "wallpaperBrowser_
  // <screen>" IPC target. Use bin/crux-focused-ipc from a keybind.
  WallpaperSelectorWindow {}

  // "wallpaper set"/"retheme" stay as flat, screen-agnostic targets — the
  // global theme and Settings.data.wallpaper.path aren't per-screen
  // concepts, so anything scripting a wallpaper change externally (bin/
  // crux-wallpaper-apply, a plugin) has one stable target regardless of
  // which monitor's browser window is open.
  IpcHandler {
    target: "wallpaper"
    function set(path: string): void {
      Settings.data.wallpaper.path = path;
      if (Settings.data.wallpaper.autoTheme)
        Matugen.generateFrom(path);
    }
    function retheme(scheme: string, colorIndex: int): void {
      Settings.data.wallpaper.matugenScheme = scheme;
      Settings.data.wallpaper.matugenColorIndex = colorIndex;
      if (Settings.data.wallpaper.path !== "")
        Matugen.generateFrom(Settings.data.wallpaper.path);
    }
  }

  // Wallpaper auto-cycle — noctalia's Wallpaper "Automation" subtab: rotate
  // to a new wallpaper from Settings.data.wallpaper.directory on a timer.
  // One global instance (not per-screen) since it drives the single shared
  // wallpaper.path setting, same one the picker/IPC `wallpaper set` above
  // write to — reuses that exact set+retheme path.
  // Boot init for singletons whose logic must not run at import time (Hooks'
  // startup hook, Idle's timeout monitors) — both self-handle Settings not
  // being loaded yet (see Hooks.qml/Idle.qml's own init()), so this can fire
  // immediately rather than waiting on Settings.isLoaded itself.
  Timer {
    id: bootTimer
    interval: 0
    running: true
    repeat: false
    onTriggered: {
      Hooks.init();
      Idle.init();
    }
  }

  Timer {
    id: wallpaperCycleTimer
    interval: Settings.data.wallpaper.autoCycleMinutes * 60 * 1000
    running: Settings.isLoaded && Settings.data.wallpaper.autoCycle
    repeat: true
    onTriggered: wallpaperCycleScan.running = true
  }

  Process {
    id: wallpaperCycleScan
    command: ["find", Settings.data.wallpaper.directory, "-maxdepth", "1", "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")"]
    stdout: StdioCollector {
      id: wallpaperCycleCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      var files = wallpaperCycleCollector.text.split("\n").filter(l => l.length > 0);
      if (files.length === 0)
        return;
      files.sort();
      var next;
      if (Settings.data.wallpaper.autoCycleMode === "sequential") {
        var idx = files.indexOf(Settings.data.wallpaper.path);
        next = files[(idx + 1) % files.length];
      } else {
        // Random, but avoid picking the same wallpaper twice in a row when
        // there's more than one candidate to choose from.
        do {
          next = files[Math.floor(Math.random() * files.length)];
        } while (files.length > 1 && next === Settings.data.wallpaper.path);
      }
      Settings.data.wallpaper.path = next;
      if (Settings.data.wallpaper.autoTheme)
        Matugen.generateFrom(next);
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
      sink.audio.volume = Math.min(1, sink.audio.volume + Settings.data.audio.step);
    }
    function decrease(): void {
      var sink = Pipewire.ready ? Pipewire.defaultAudioSink : null;
      if (!sink || !sink.audio)
        return;
      sink.audio.volume = Math.max(0, sink.audio.volume - Settings.data.audio.step);
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
      // A screen taller than it is wide (a physically rotated portrait
      // monitor, e.g. this box's DP-1) makes a "top"/"bottom" bar span its
      // *short* edge — much less room than a normal landscape top bar has,
      // even though the bar itself is still a physically horizontal strip.
      // Widget-internal content (Clock's date+time, StatusGroup's NET/VOL
      // pairs, etc.) should use the same compact/stacked style a true
      // vertical bar already has for exactly that reason — see
      // Bar.qml/BarSection.qml's contentVertical.
      readonly property bool screenIsPortrait: screen.height > screen.width
      // NOT blanket-applied to every widget (see BarWidgetLoader.qml's
      // _compactSafeIds) — confirmed real breakage doing that: Tray's and
      // Workspaces' `vertical` prop means "stack items along the bar's long
      // axis", which only has room on a real vertical (left/right) bar.
      // Forcing it on for a horizontal top bar just because the screen is
      // portrait made Tray's icons stack downward past the bar's own height
      // with nothing bounding them. Only widgets confirmed to fit a modest
      // thickness bump (short text stacks, not multi-item grids) opt in.
      readonly property bool contentVertical: barIsVertical || screenIsPortrait
      // contentVertical's compact/stacked widget styles (2-3 lines) need
      // more cross-axis room than the bar's normal single-line thickness
      // provides — true vertical bars already have that room along their
      // own long axis, but a "top"/"bottom" bar's cross-axis *is* its
      // thickness setting, which doesn't grow on its own just because the
      // content inside got taller. Bump it here specifically for the
      // portrait-on-horizontal-bar case (confirmed via screenshot: without
      // this, Clock's stacked HH/mm/date visibly overflowed past the
      // bottom of its own chamfered module).
      readonly property bool compactOnHorizontalBar: contentVertical && !barIsVertical
      readonly property int effectiveThickness: compactOnHorizontalBar ? Math.max(Settings.data.bar.thickness, 56) : Settings.data.bar.thickness
      readonly property bool autoHide: Settings.data.bar.autoHide
      readonly property bool shownOnThisScreen: Settings.data.bar.monitors.length === 0 || Settings.data.bar.monitors.includes(screen.name)
      property bool hovered: false
      // Auto-hide fades the bar out until the pointer reaches its screen
      // edge; the PanelWindow itself always stays mapped (full opacity 0
      // wouldn't remove it from the compositor, wlr-layer-shell surfaces
      // aren't reactive to CSS-style display:none) so hover detection still
      // works while it's visually hidden.
      readonly property bool barShown: !autoHide || hovered

      anchors {
        top: barPosition === "top" || barIsVertical
        bottom: barPosition === "bottom" || barIsVertical
        left: barPosition === "left" || !barIsVertical
        right: barPosition === "right" || !barIsVertical
      }
      readonly property int effectiveFloatMargin: Settings.data.bar.floating ? Settings.data.bar.floatMargin : 0
      margins {
        top: root.effectiveFloatMargin
        bottom: root.effectiveFloatMargin
        left: root.effectiveFloatMargin
        right: root.effectiveFloatMargin
      }
      // When vertical, top+bottom anchors fill height and only implicitWidth matters (and vice versa).
      implicitWidth: root.effectiveThickness
      implicitHeight: root.effectiveThickness
      // Transparent so the margins above actually read as a floating gap
      // around a rounded pill (the Rectangle below), not a plain inset
      // rectangle on a same-colored background.
      color: "transparent"

      // Fully unmapped (not just faded/transparent) on a screen the
      // Monitors list excludes — Settings.data.bar.monitors was previously
      // written by the settings panel's checkboxes but never actually read
      // anywhere, so toggling a monitor off did nothing.
      visible: root.shownOnThisScreen

      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.namespace: "crux-bar"
      // Auto-hide doesn't reserve screen space — that's the point of it;
      // windows can use the strip the bar only occupies while shown.
      WlrLayershell.exclusionMode: root.autoHide ? ExclusionMode.Ignore : ExclusionMode.Auto

      HoverHandler {
        onHoveredChanged: root.hovered = hovered
      }

      // Transparent bar + edge-glow line by default; a real bar-strip
      // background is opt-in via Settings.data.bar.showBackground — see
      // crux skill's notes.md for why this is a toggle, not the default.
      Item {
        id: barRect
        anchors.fill: parent
        opacity: root.barShown ? 1 : 0
        Behavior on opacity {
          NumberAnimation {
            duration: Style.animationNormal
          }
        }

        Chamfer {
          // Real bar-strip background — off by default (showBackground).
          // Same two-opposite-corner convention as every other chamfered
          // surface in crux while floating; square (flush) when docked.
          visible: Settings.data.bar.showBackground
          anchors.fill: parent
          chamferSize: Settings.data.bar.floating ? Tokens.chamferPanel : 0
          cutTopRight: Settings.data.bar.floating
          cutBottomLeft: Settings.data.bar.floating
          fillColor: Color.alpha(Color.surface, Settings.data.bar.barBackgroundOpacity)
          strokeColor: "transparent"
        }

        Rectangle {
          // Plain x/y/width/height instead of anchors — anchors that
          // conditionally switch a side between a real target and
          // `undefined` (needed here since which edge this hugs depends on
          // barIsVertical/barPosition) don't reliably re-resolve once
          // Settings finishes loading: this binding first evaluates while
          // Settings.isLoaded is still false (barPosition defaults to
          // "top"/horizontal for every screen), and a screen whose real
          // configured position is actually vertical never correctly
          // flipped its anchors over afterward — confirmed via a debug
          // console.log that fired with vertical=false/position=top on a
          // screen configured as "left", and confirmed the line rendered
          // fine on the "top" screen (no flip ever needed) but never on the
          // "left" one (needed a flip that never took). Plain property
          // bindings don't have that staleness — they fully re-evaluate.
          visible: Settings.data.bar.showBorder
          x: root.barIsVertical ? (root.barPosition === "left" ? parent.width - Settings.data.bar.borderWidth : 0) : 0
          y: root.barIsVertical ? 0 : (root.barPosition === "top" ? parent.height - Settings.data.bar.borderWidth : 0)
          width: root.barIsVertical ? Settings.data.bar.borderWidth : parent.width
          height: root.barIsVertical ? parent.height : Settings.data.bar.borderWidth
          color: "transparent"

          gradient: Gradient {
            orientation: root.barIsVertical ? Gradient.Vertical : Gradient.Horizontal
            GradientStop {
              position: 0
              color: Color.alpha(Color.primary, 0)
            }
            GradientStop {
              position: 0.3
              color: Color.alpha(Color.primary, 0.32)
            }
            GradientStop {
              position: 0.7
              color: Color.alpha(Color.primary, 0.32)
            }
            GradientStop {
              position: 1
              color: Color.alpha(Color.primary, 0)
            }
          }
        }

        Bar {
          screen: root.screen
          vertical: root.barIsVertical
          contentVertical: root.contentVertical
        }
      }

      VolumeOsd {
        targetScreen: root.screen
      }

      TooltipOverlay {
        targetScreen: root.screen
      }

      NotificationsWindow {
        targetScreen: root.screen
      }

      SidebarWindow {
        targetScreen: root.screen
      }

      // Always exists per screen regardless of which bar widgets are
      // configured — StatusGroup and the standalone ControlCenter icon
      // both just reach it over the "controlCenter" IPC target (see
      // ControlCenterWindow.qml's openAt). Previously this was only ever
      // instantiated as a child of StatusGroup.qml, so it silently didn't
      // exist at all — and the IPC target never registered — on a bar
      // layout that dropped StatusGroup in favor of just the standalone
      // icon (confirmed via `qs ipc show` listing no "controlCenter"
      // target at all).
      ControlCenterWindow {
        targetScreen: root.screen
      }
    }
  }
}
