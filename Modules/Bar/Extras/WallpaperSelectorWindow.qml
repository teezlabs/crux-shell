import Quickshell
import qs.Modules.Bar.Extras

// One WallpaperBrowserWindow per screen, same per-screen popup pattern as
// SettingsWindow — each registers its own "wallpaperBrowser_<screen>" IPC
// target; use bin/crux-focused-ipc from a keybind to reach whichever one is
// actually focused instead of always hitting screens[0]. See crux skill's
// notes.md.
Variants {
  model: Quickshell.screens

  WallpaperBrowserWindow {
    required property var modelData
    targetScreen: modelData
  }
}
