import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

// Wallpaper strip under the floating bar, hiding scrolled-off windows that
// the scrolling layout still draws in the bar's reserved area.
PanelWindow {
  id: root

  property var targetScreen: null
  property string barPosition: "top"
  screen: targetScreen

  readonly property bool vertical: barPosition === "left" || barPosition === "right"

  anchors {
    top: root.barPosition === "top" || root.vertical
    bottom: root.barPosition === "bottom" || root.vertical
    left: root.barPosition === "left" || !root.vertical
    right: root.barPosition === "right" || !root.vertical
  }
  implicitWidth: Tokens.barExtent + Tokens.barMargin
  implicitHeight: Tokens.barExtent + Tokens.barMargin
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "crux-bar-backdrop"
  exclusionMode: ExclusionMode.Ignore

  readonly property string wallpaperPath: Settings.isLoaded && targetScreen ? Settings.getWallpaperForScreen(targetScreen.name) : ""

  Image {
    x: root.barPosition === "right" ? root.width - width : 0
    y: root.barPosition === "bottom" ? root.height - height : 0
    width: root.targetScreen ? root.targetScreen.width : 0
    height: root.targetScreen ? root.targetScreen.height : 0
    source: root.wallpaperPath ? "file://" + root.wallpaperPath : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: true
  }
}
