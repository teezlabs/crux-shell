import Quickshell
import qs.Modules.Bar.Extras

// One WallpaperBrowserWindow per screen. The "wallpaperBrowser" IPC target
// is claimed only by whichever instance is on the currently-focused
// monitor; each also has its own "wallpaperBrowser_<screen>" target for
// same-screen callers (the bar widget) that don't need focus routing.
Variants {
  model: Quickshell.screens

  WallpaperBrowserWindow {
    required property var modelData
    targetScreen: modelData
  }
}
