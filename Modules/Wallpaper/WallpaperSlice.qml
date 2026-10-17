import QtQuick
import QtQuick.Shapes
import qs.Commons
import qs.Widgets

// One parallelogram slice of the wallpaper strip, after skwd-wall's slice view.
// The slant comes from shearing a clipping container and counter-shearing the image
// inside it: Qt clips that with the stencil buffer, so a slice needs no layer or mask
// effect, which is what made the per-slice MultiEffect version lag.
Item {
  id: slice

  required property var modelData
  required property int index

  property real sliceWidth: 135
  property real expandedWidth: 768
  property real skew: 28

  signal picked(int index)
  signal applyRequested

  readonly property ListView view: ListView.view
  readonly property bool current: ListView.isCurrentItem
  readonly property bool isVideo: !modelData.isRemote && (modelData.ext === "mp4" || modelData.ext === "webm")
  readonly property bool isRemote: !!modelData.isRemote
  readonly property real _shear: slice.skew / Math.max(1, slice.height)

  width: slice.current ? slice.expandedWidth : slice.sliceWidth
  height: view ? view.height : 0
  // The focused slice's slants draw over its neighbours'.
  z: slice.current ? 2 : (hover.hovered ? 1 : 0)

  // Fades out toward the strip's ends.
  readonly property real _distance: view ? Math.abs(slice.x + slice.width / 2 - (view.contentX + view.width / 2)) / (view.width / 2) : 0
  opacity: slice._distance < 0.6 ? 1 : Math.max(0, 1 - (slice._distance - 0.6) / 0.5)

  Behavior on width {
    NumberAnimation {
      duration: Tokens.durationSidebarSlide
      easing.type: Tokens.easingSidebarSlide
    }
  }

  // Sheared clip: its own rect maps to the parallelogram (skew,0) (w,0) (w-skew,h) (0,h).
  Item {
    id: clipper
    width: slice.width - slice.skew
    height: slice.height
    clip: true
    transform: Matrix4x4 {
      matrix: Qt.matrix4x4(1, -slice._shear, 0, slice.skew, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
    }

    Rectangle {
      width: slice.width
      height: slice.height
      color: Colors.surfaceContainer
    }

    // Counter-sheared, so the picture itself stays upright inside the slant.
    Item {
      width: slice.width
      height: slice.height
      transform: Matrix4x4 {
        matrix: Qt.matrix4x4(1, slice._shear, 0, -slice.skew, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
      }

      Image {
        id: thumb
        anchors.fill: parent
        source: slice.isVideo ? "" : slice.isRemote ? slice.modelData.thumb : "file://" + slice.modelData.path
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        // Decoded once at the expanded size, so focusing a slice never re-decodes it.
        sourceSize: Qt.size(slice.expandedWidth, slice.height)
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity {
          NumberAnimation {
            duration: Tokens.durationPanel
          }
        }
      }

      // A Wallhaven thumb is small; the focused card loads the full image over it.
      Image {
        anchors.fill: parent
        visible: slice.current && slice.isRemote && status === Image.Ready
        source: slice.current && slice.isRemote ? slice.modelData.path : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize: Qt.size(slice.expandedWidth, slice.height)
      }

      NText {
        visible: slice.isVideo && slice.current
        anchors.centerIn: parent
        tracking: true
        text: "VIDEO"
        color: Colors.labelText
        size: NText.Size.LabelXs
      }
    }

    Rectangle {
      width: slice.width
      height: slice.height
      color: Qt.rgba(0, 0, 0, slice.current ? 0 : (hover.hovered ? 0.2 : 0.5))
      Behavior on color {
        ColorAnimation {
          duration: Tokens.durationPanel
        }
      }
    }
  }

  // Anti-aliased, and drawn over the stencil clip's stepped edge to hide it.
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      fillColor: "transparent"
      strokeColor: slice.current ? Colors.primary : (hover.hovered ? Colors.alpha(Colors.primary, 0.5) : Colors.outline)
      strokeWidth: slice.current ? 2 : Tokens.borderModule
      joinStyle: ShapePath.MiterJoin
      PathPolyline {
        readonly property real i: slice.current ? 1 : 0.5
        path: [Qt.point(slice.skew + i, i), Qt.point(slice.width - i, i), Qt.point(slice.width - slice.skew - i, slice.height - i), Qt.point(i, slice.height - i), Qt.point(slice.skew + i, i)]
      }
    }
  }

  // Type badge on the focused slice.
  Item {
    visible: slice.current
    x: slice.skew + 10
    y: 10
    width: badge.implicitWidth + 10
    height: 16
    Rectangle {
      anchors.fill: parent
      color: slice.isVideo ? Colors.alpha(Colors.tertiary, 0.85) : slice.isRemote ? Colors.alpha(Colors.primary, 0.85) : Colors.alpha(Colors.surface, 0.75)
    }
    NText {
      id: badge
      anchors.centerIn: parent
      tracking: true
      text: slice.isVideo ? "VID" : slice.isRemote ? "WEB" : "IMG"
      color: (slice.isVideo || slice.isRemote) ? Colors.primaryText : Colors.labelText
      size: NText.Size.LabelXs
    }
  }

  // Hits only inside the parallelogram, not the triangles a neighbour's slant overlaps.
  containmentMask: QtObject {
    function contains(point: point): bool {
      const t = point.y / Math.max(1, slice.height);
      const left = slice.skew * (1 - t);
      const right = slice.width - slice.skew * t;
      return point.x >= left && point.x <= right && point.y >= 0 && point.y <= slice.height;
    }
  }

  HoverHandler {
    id: hover
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    onTapped: slice.picked(slice.index)
    onDoubleTapped: slice.applyRequested()
  }
}
