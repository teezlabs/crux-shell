//@ pragma UseQApplication
// crux shell entry point (`qs -c crux`). UseQApplication is required for the tray's DBusMenu popups.

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Modules.Background
import qs.Modules.Bar
import qs.Modules.ControlCenter
import qs.Modules.Notifications
import qs.Modules.Popups
import qs.Modules.Sidebar
import qs.Modules.Wallpaper
import qs.Modules.LockScreen
import qs.Modules.OSD
import qs.Modules.Polkit
import qs.Modules.Tooltip
// Imported, not instantiated: a module reached only from a Loader-loaded bar widget needs one static import to register.
import qs.Modules.Launcher
import qs.Modules.Popups.Contents
import qs.Modules.SessionMenu
import qs.Modules.SettingsPanel
import qs.Modules.SettingsPanel.Controls
import qs.Widgets
import qs.Services

ShellRoot {
  PolkitAgent {}

  Background {}

  DesktopWidgets {}

  ToastOverlay {}

  LockScreen {}

  // Wallpaper browser, one per screen; "wallpaperBrowser" routes to the focused monitor's instance.
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

  // Boot init for singletons that must not run at import time.
  Timer {
    id: bootTimer
    interval: 0
    running: true
    repeat: false
    onTriggered: {
      Hooks.init();
      Idle.init();
      NightLightService.init();
      WindowCorners.init();
      ClipboardService.init();
      applyReverseScroll();
    }
  }

  // natural_scroll is a runtime Hyprland keyword, so it's applied on every boot and live on toggle.
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
        // Random, but never the same wallpaper twice in a row when there's a choice.
        do {
          next = files[Math.floor(Math.random() * files.length)];
        } while (files.length > 1 && next === Settings.data.wallpaper.path);
      }
      Settings.data.wallpaper.path = next;
      if (Settings.data.wallpaper.autoTheme)
        Matugen.generateFrom(next);
    }
  }

  // Volume IPC for the media keys (keybinds.lua) and anything else nudging the default sink.
  IpcHandler {
    target: "volume"
    function increase(): void {
      var sink = Pipewire.ready ? Pipewire.defaultAudioSink : null;
      if (!sink || !sink.audio)
        return;
      sink.audio.muted = false;
      sink.audio.volume = Math.min(Settings.data.audio.volumeOverdrive ? 1.5 : 1, sink.audio.volume + Settings.data.audio.step);
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

  // Screen-agnostic popup IPC targets, once for the whole shell.
  PopupAliases {}

  // Night light from a keybind, through the same service as the bar widget and Control Center.
  IpcHandler {
    target: "nightLight"
    function status(): string {
      return NightLightService.forced ? "forced" : (NightLightService.enabled ? "on" : "off");
    }
    function cycle(): string {
      NightLightService.cycle();
      return status();
    }
    function on(): string {
      NightLightService.setEnabled(true);
      return status();
    }
    function off(): string {
      NightLightService.setEnabled(false);
      return status();
    }
  }

  // Keep-awake from a keybind, sharing the bar widget's and Control Center's state.
  IpcHandler {
    target: "keepAwake"
    function status(): string {
      return IdleInhibitorService.active ? "on" : "off";
    }
    function toggle(): string {
      IdleInhibitorService.toggle();
      return IdleInhibitorService.active ? "on" : "off";
    }
    function on(): string {
      IdleInhibitorService.setActive(true);
      return "on";
    }
    function off(): string {
      IdleInhibitorService.setActive(false);
      return "off";
    }
  }

  // Power profile from a keybind, without going through the bar icon.
  IpcHandler {
    target: "powerProfile"
    function current(): string {
      return PowerProfileService.available ? PowerProfileService.key() : "unavailable";
    }
    function cycle(): string {
      PowerProfileService.cycle();
      return PowerProfileService.key();
    }
    function set(name: string): string {
      PowerProfileService.setProfile(PowerProfileService.fromKey(name));
      return PowerProfileService.key();
    }
  }

  // Theming from a keybind or script, without going through the panel.
  IpcHandler {
    target: "darkMode"
    function status(): string {
      return Matugen.darkMode ? "dark" : "light";
    }
    function toggle(): string {
      Matugen.toggleDarkMode();
      return status();
    }
    function set(mode: string): string {
      Matugen.setDarkMode(mode !== "light");
      return status();
    }
  }

  IpcHandler {
    target: "theme"
    function schemes(): string {
      return ColorSchemes.schemes.map(s => s.name).join("\n");
    }
    function scheme(name: string): string {
      ColorSchemes.apply(name);
      return name;
    }
    function current(): string {
      return Settings.data.theme.colorScheme || "(wallpaper colors)";
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
      // docs/design-notes.md, "Portrait-monitor bar"; only widgets confirmed safe use it.
      readonly property bool contentVertical: barIsVertical || screenIsPortrait
      readonly property int effectiveThickness: Settings.data.bar.thickness
      readonly property bool autoHide: Settings.data.bar.autoHide
      readonly property bool shownOnThisScreen: Settings.data.bar.monitors.length === 0 || Settings.data.bar.monitors.includes(screen.name)
      property bool hovered: false
      // Stays mapped while auto-hidden so hover detection keeps working.
      readonly property bool barShown: !autoHide || hovered

      anchors {
        top: barPosition === "top" || barIsVertical
        bottom: barPosition === "bottom" || barIsVertical
        left: barPosition === "left" || !barIsVertical
        right: barPosition === "right" || !barIsVertical
      }
      readonly property int effectiveFloatMargin: Tokens.barMargin
      margins {
        top: root.effectiveFloatMargin
        bottom: root.effectiveFloatMargin
        left: root.effectiveFloatMargin
        right: root.effectiveFloatMargin
      }
      // When vertical, top+bottom anchors fill height and only implicitWidth matters (and vice versa).
      readonly property int joinGap: Tokens.barDocked ? Tokens.barJoinGap : 0
      implicitWidth: root.effectiveThickness + root.joinGap
      implicitHeight: root.effectiveThickness + root.joinGap
      // Transparent so the margins read as a gap around the floating pill.
      color: "transparent"

      // Unmapped on screens the Monitors list excludes. Waits for Settings (or margins lock in at defaults) and for the backdrop, so it maps first and stacks below.
      visible: root.shownOnThisScreen && Settings.isLoaded && (root.autoHide || backdrop.visible)

      BarBackdrop {
        id: backdrop
        targetScreen: root.screen
        barPosition: root.barPosition
        visible: root.shownOnThisScreen && Settings.isLoaded && !root.autoHide
      }

      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.namespace: "crux-bar"
      // Auto-hide reserves no space; windows get the strip back while the bar is hidden.
      WlrLayershell.exclusionMode: root.autoHide ? ExclusionMode.Ignore : ExclusionMode.Auto

      HoverHandler {
        onHoveredChanged: root.hovered = hovered
      }

      // Transparent bar with an edge-glow line by default; the strip background is opt-in (docs/design-notes.md).
      Item {
        id: barRect
        anchors.fill: parent
        opacity: root.barShown ? 1 : 0
        Behavior on opacity {
          NumberAnimation {
            duration: Tokens.durationBarFade
          }
        }

        Chamfer {
          // Bar-strip background: floating, it cuts opposite corners at its ends; square when docked.
          visible: Settings.data.bar.showBackground
          anchors.fill: parent
          chamferSize: Settings.data.bar.floating ? Tokens.chamferBarFloating : 0
          cutTopRight: Settings.data.bar.floating
          cutBottomLeft: Settings.data.bar.floating
          fillColor: Colors.alpha(Colors.barSurface, Settings.data.bar.barBackgroundOpacity)
          strokeColor: Tokens.barPill ? Colors.outline : "transparent"
          strokeWidth: Tokens.borderPanel
        }

        // Outline following the background's chamfered shape.
        Chamfer {
          visible: Settings.data.bar.showBorder
          anchors.fill: parent
          chamferSize: Settings.data.bar.floating ? Tokens.chamferBarFloating : 0
          cutTopRight: Settings.data.bar.floating
          cutBottomLeft: Settings.data.bar.floating
          fillColor: "transparent"
          strokeColor: Colors.alpha(Colors.primary, 0.32)
          strokeWidth: Settings.data.bar.borderWidth
        }

        // Inner edge line that SlideCard drawers overlap and join into.
        Rectangle {
          visible: Tokens.barDocked && !Settings.data.bar.showBorder
          x: root.barPosition === "left" ? parent.width - width : 0
          y: root.barPosition === "top" ? parent.height - height : 0
          width: root.barIsVertical ? Tokens.borderPanel : parent.width
          height: root.barIsVertical ? parent.height : Tokens.borderPanel
          color: Colors.outline
        }

        // Modules keep the configured thickness; joinGap is extra strip on the inner side.
        Item {
          x: root.barPosition === "right" ? root.joinGap : 0
          y: root.barPosition === "bottom" ? root.joinGap : 0
          width: root.barIsVertical ? root.effectiveThickness : parent.width
          height: root.barIsVertical ? parent.height : root.effectiveThickness

          Bar {
            screen: root.screen
            vertical: root.barIsVertical
            contentVertical: root.contentVertical
          }
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

      // Always-mapped popup overlay, one per screen, independent of which bar widgets are configured.
      PopupHost {
        targetScreen: root.screen
      }
    }
  }
}
