import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

// Desktop wallpaper layer: one PanelWindow per screen at the WlrLayer.Background
// z-level, showing Settings.data.wallpaper.path (set live by
// `qs ipc call wallpaper set <path>`, driven by aurora-wallpaper-apply from the
// skwd-wall picker). Deliberately NOT a port of noctalia's Background.qml — that
// one is an 800-line shader-based transition system (fade/wipe/disc/stripes/
// pixelate/honeycomb, compositor-scale-aware caching) coupled to services crux
// doesn't have. This is a plain two-layer crossfade instead: same practical
// result (no jarring pop when switching wallpapers) at a fraction of the
// complexity. Revisit only if the plain fade actually feels lacking.
Variants {
  model: Quickshell.screens

  PanelWindow {
    id: root
    required property var modelData
    screen: modelData

    color: "transparent"
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "crux-wallpaper"
    exclusionMode: ExclusionMode.Ignore

    readonly property string targetPath: Settings.data.wallpaper.path
    readonly property string targetUrl: targetPath ? "file://" + targetPath : ""

    // Two stacked Image layers; whichever isn't currently on top silently
    // loads the new path, then a Behavior on opacity crossfades it in once
    // ready — swapping a single Image's own `source` pops instantly instead.
    property bool topIsA: true

    onTargetUrlChanged: {
      var back = topIsA ? imgB : imgA;
      back.source = targetUrl;
    }

    Image {
      id: imgA
      anchors.fill: parent
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: true
      opacity: root.topIsA ? 1 : 0
      Behavior on opacity {
        NumberAnimation {
          duration: 500
          easing.type: Easing.InOutQuad
        }
      }
      onStatusChanged: if (status === Image.Ready && !root.topIsA)
        root.topIsA = true
    }

    Image {
      id: imgB
      anchors.fill: parent
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: true
      opacity: root.topIsA ? 0 : 1
      Behavior on opacity {
        NumberAnimation {
          duration: 500
          easing.type: Easing.InOutQuad
        }
      }
      onStatusChanged: if (status === Image.Ready && root.topIsA)
        root.topIsA = false
    }

    Component.onCompleted: imgA.source = root.targetUrl
  }
}
