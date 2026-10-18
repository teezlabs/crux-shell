import QtQuick
import QtQuick.Shapes
import qs.Commons
import qs.Widgets

// One parallelogram slice of the wallpaper strip (after skwd-wall), filled by an anti-aliased Shape (docs/design-notes.md).
Item {
  id: slice

  required property var modelData
  required property int index

  // A cached downscaled copy of a local image, when one exists.
  property string thumbPath: ""
  property real sliceWidth: 135
  property real expandedWidth: 768
  property real skew: 28

  signal picked(int index)
  signal applyRequested

  readonly property ListView view: ListView.view
  readonly property bool current: ListView.isCurrentItem
  readonly property bool isVideo: !modelData.isRemote && (modelData.ext === "mp4" || modelData.ext === "webm")
  readonly property bool isRemote: !!modelData.isRemote

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

  // Texture sources only, sized to their decoded pixels and centred by fillTransform.
  Image {
    id: thumb
    visible: false
    source: slice.isVideo ? "" : slice.isRemote ? slice.modelData.thumb : "file://" + (slice.thumbPath || slice.modelData.path)
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: true
    // Decoded once at the expanded size, so focusing a slice never re-decodes it.
    sourceSize: Qt.size(slice.expandedWidth, slice.height)
  }
  // A Wallhaven thumb is small; the focused card swaps in the full image once loaded.
  Image {
    id: full
    visible: false
    source: slice.current && slice.isRemote ? slice.modelData.path : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    sourceSize: Qt.size(slice.expandedWidth, slice.height)
  }
  readonly property Image _source: full.status === Image.Ready ? full : thumb

  readonly property var _outline: {
    const i = slice.current ? 1 : 0.5;
    return [Qt.point(slice.skew + i, i), Qt.point(slice.width - i, i), Qt.point(slice.width - slice.skew - i, slice.height - i), Qt.point(i, slice.height - i), Qt.point(slice.skew + i, i)];
  }

  // The image fills the parallelogram, so the curve renderer anti-aliases its edges.
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeColor: "transparent"
      fillColor: Colors.surfaceContainer
      fillItem: slice._source.status === Image.Ready ? slice._source : null
      fillTransform: PlanarTransform.fromTranslate((slice.width - slice._source.width) / 2, (slice.height - slice._source.height) / 2)
      PathPolyline {
        path: [Qt.point(slice.skew, 0), Qt.point(slice.width, 0), Qt.point(slice.width - slice.skew, slice.height), Qt.point(0, slice.height), Qt.point(slice.skew, 0)]
      }
    }

    ShapePath {
      fillColor: Qt.rgba(0, 0, 0, slice.current ? 0 : (hover.hovered ? 0.2 : 0.5))
      strokeColor: slice.current ? Colors.primary : (hover.hovered ? Colors.alpha(Colors.primary, 0.5) : Colors.outline)
      strokeWidth: slice.current ? 2 : Tokens.borderModule
      joinStyle: ShapePath.MiterJoin
      PathPolyline {
        path: slice._outline
      }
    }
  }

  NText {
    visible: slice.isVideo && slice.current
    anchors.centerIn: parent
    tracking: true
    text: "VIDEO"
    color: Colors.labelText
    size: NText.Size.LabelXs
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
