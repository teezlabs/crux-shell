//@ pragma UseQApplication
// crux shell entry point. Launch with `qs -c crux`.
// UseQApplication is required for Tray.qml's right-click DBusMenu popups
// (QsMenuAnchor.open() fails without it) — don't remove.

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
// Not instantiated here — statically imported once so the Settings.qml bar
// widget's own dynamic Loader can resolve qs.Modules.SettingsPanel. See
// crux skill's SKILL.md.
import qs.Modules.SettingsPanel
import qs.Modules.SettingsPanel.Controls

ShellRoot {
  PolkitAgent {}

  Background {}

  DesktopWidgets {}

  ToastOverlay {}

  LockScreen {}

  // Crux's own fullscreen wallpaper browser — one instance per screen (see
  // WallpaperSelectorWindow.qml). The shared "wallpaperBrowser" IPC target
  // routes to whichever instance is on the currently-focused monitor.
  WallpaperSelectorWindow {}

  // Flat, screen-agnostic IPC target — wallpaper.path/theme aren't per-screen concepts.
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

  // Boot init for singletons whose logic must not run at import time
  // (Hooks/Idle self-handle Settings not being loaded yet via their own
  // init()), so this can fire immediately.
  Timer {
    id: bootTimer
    interval: 0
    running: true
    repeat: false
    onTriggered: {
      Hooks.init();
      Idle.init();
      applyReverseScroll();
    }
  }

  // input:natural_scroll is a runtime Hyprland keyword, not something
  // hyprland.lua sets once at compositor startup — needs re-applying on
  // every boot, plus live on toggle (see the Connections below).
  Process {
    id: reverseScrollProc
  }
  function applyReverseScroll() {
    reverseScrollProc.command = ["hyprctl", "keyword", "input:natural_scroll", Settings.data.general.reverseScroll ? "true" : "false"];
    reverseScrollProc.running = true;
  }
  Connections {
    target: Settings.data.general
    function onReverseScrollChanged() {
      applyReverseScroll();
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

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: root
      required property var modelData
      screen: modelData

      readonly property string barPosition: Settings.isLoaded ? Settings.getBarPositionForScreen(screen.name) : "top"
      readonly property bool barIsVertical: barPosition === "left" || barPosition === "right"
      readonly property bool screenIsPortrait: screen.height > screen.width
      // See crux skill's notes.md (Portrait-monitor bar section) — not
      // blanket-applied to every widget, only ones confirmed safe.
      readonly property bool contentVertical: barIsVertical || screenIsPortrait
      // Used to be floored at 56px here for portrait-screen horizontal
      // bars, because Sound/ControlCenter grew taller in that case and
      // overflowed a thinner bar. Both are fixed to stay standard-height
      // now (see crux skill's notes.md), so the floor no longer applies.
      readonly property int effectiveThickness: Settings.data.bar.thickness
      readonly property bool autoHide: Settings.data.bar.autoHide
      readonly property bool shownOnThisScreen: Settings.data.bar.monitors.length === 0 || Settings.data.bar.monitors.includes(screen.name)
      property bool hovered: false
      // PanelWindow stays mapped even when auto-hidden (layer-shell surfaces
      // aren't display:none-reactive), so hover detection still works.
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

        // Solid outline framing all four edges of the bar, following the
        // same chamfered shape as the background above it instead of a
        // plain square-cornered Rectangle border.
        Chamfer {
          visible: Settings.data.bar.showBorder
          anchors.fill: parent
          chamferSize: Settings.data.bar.floating ? Tokens.chamferPanel : 0
          cutTopRight: Settings.data.bar.floating
          cutBottomLeft: Settings.data.bar.floating
          fillColor: "transparent"
          strokeColor: Color.alpha(Color.primary, 0.32)
          strokeWidth: Settings.data.bar.borderWidth
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
