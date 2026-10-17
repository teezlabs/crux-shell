import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Services

// Wallpaper strip under the floating bar, hiding scrolled-off windows that
// the scrolling layout still draws in the bar's reserved area and gaps_out.
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
  readonly property int extent: Tokens.barExtent + Tokens.barMargin + HyprGaps.forEdge(barPosition)
  implicitWidth: extent
  implicitHeight: extent
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "crux-bar-backdrop"
  exclusionMode: ExclusionMode.Ignore

  readonly property string wallpaperPath: Settings.isLoaded && targetScreen ? Settings.getWallpaperForScreen(targetScreen.name) : ""

  // Solid up to the bar's outer edge, then fades out by the work area's edge.
  readonly property bool fadesForward: barPosition === "top" || barPosition === "left"
  readonly property real solidStop: extent > 0 ? Tokens.barExtent / extent : 1

  Item {
    id: strip
    anchors.fill: parent
    clip: true
    visible: false
    layer.enabled: true

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

  Rectangle {
    id: fadeMask
    anchors.fill: parent
    visible: false
    layer.enabled: true
    gradient: Gradient {
      orientation: root.vertical ? Gradient.Horizontal : Gradient.Vertical
      GradientStop {
        position: 0
        color: Qt.rgba(0, 0, 0, root.fadesForward ? 1 : 0)
      }
      GradientStop {
        position: root.fadesForward ? root.solidStop : 1 - root.solidStop
        color: Qt.rgba(0, 0, 0, 1)
      }
      GradientStop {
        position: 1
        color: Qt.rgba(0, 0, 0, root.fadesForward ? 0 : 1)
      }
    }
  }

  MultiEffect {
    anchors.fill: parent
    source: strip
    maskEnabled: true
    maskSource: fadeMask
    maskThresholdMin: 0.5
    maskSpreadAtMin: 1
  }
}
