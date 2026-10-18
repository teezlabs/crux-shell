import Quickshell

// One browser per screen. "wallpaperBrowser" goes to the focused monitor's; "wallpaperBrowser_<screen>" to a specific one.
Variants {
  model: Quickshell.screens

  WallpaperBrowserWindow {
    required property var modelData
    targetScreen: modelData
  }
}
