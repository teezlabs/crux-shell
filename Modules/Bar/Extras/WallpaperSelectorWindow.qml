import Quickshell
import qs.Modules.Bar.Extras

// One WallpaperBrowserWindow per screen, each with its own IPC target; use bin/crux-focused-ipc to reach the focused one.
Variants {
  model: Quickshell.screens

  WallpaperBrowserWindow {
    required property var modelData
    targetScreen: modelData
  }
}
