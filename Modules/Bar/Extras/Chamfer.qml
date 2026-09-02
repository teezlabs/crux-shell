import QtQuick
import QtQuick.Shapes

// Chamfered-rectangle background, no rounded corners. Per-corner cut flags.
Item {
  id: root

  property int chamferSize: 8
  property bool cutTopLeft: false
  property bool cutTopRight: false
  property bool cutBottomLeft: false
  property bool cutBottomRight: false
  property color fillColor: "transparent"
  property color strokeColor: "transparent"
  property real strokeWidth: 0
  // "top"/"right"/"bottom"/"left"/"" — skips drawing the stroke on that one
  // edge (e.g. a popup flush against the bar shouldn't outline the edge
  // touching it, so it reads as growing out of the bar instead of a fully
  // separate bordered card). The fill still covers the full shape.
  property string omitStrokeSide: ""

  // The fill is one closed PathPolyline loop — this part of Qt Quick
  // Shapes has always rendered correctly, verified repeatedly.
  Shape {
    anchors.fill: parent
    ShapePath {
      fillColor: root.fillColor
      strokeColor: "transparent"
      PathPolyline {
        path: {
          var tl = root.cutTopLeft ? [Qt.point(0, root.chamferSize), Qt.point(root.chamferSize, 0)] : [Qt.point(0, 0)];
          var tr = root.cutTopRight ? [Qt.point(root.width - root.chamferSize, 0), Qt.point(root.width, root.chamferSize)] : [Qt.point(root.width, 0)];
          var br = root.cutBottomRight ? [Qt.point(root.width, root.height - root.chamferSize), Qt.point(root.width - root.chamferSize, root.height)] : [Qt.point(root.width, root.height)];
          var bl = root.cutBottomLeft ? [Qt.point(root.chamferSize, root.height), Qt.point(0, root.height - root.chamferSize)] : [Qt.point(0, root.height)];
          var pts = [].concat(tl, tr, br, bl);
          pts.push(pts[0]);
          return pts;
        }
      }
    }
  }

  // The stroke is built from plain Rectangles for the 4 straight edges
  // (each inset to stop short of a cut corner) plus a tiny 2-point Shape
  // per cut corner for its diagonal. Not a Shape-drawn closed/open
  // polyline like the fill: confirmed live that Qt Quick Shapes silently
  // drops the render of one specific straight stroke segment in this
  // popup-border configuration — reproduced with a single self-contained
  // 2-point PathPolyline, an independent per-segment ShapePath, reversed
  // point order, and a widened strokeWidth (which DID paint, just with
  // the wrong geometry, ruling out a pure clipping explanation) — with
  // correct, verified-via-runtime-log geometry and color every time.
  // Rectangles sidestep whatever that Shape-specific bug is entirely.

  // top
  Rectangle {
    visible: root.omitStrokeSide !== "top"
    color: root.strokeColor
    x: root.cutTopLeft ? root.chamferSize : 0
    y: -root.strokeWidth / 2
    width: (root.cutTopRight ? root.width - root.chamferSize : root.width) - x
    height: root.strokeWidth
  }
  // right
  Rectangle {
    visible: root.omitStrokeSide !== "right"
    color: root.strokeColor
    x: root.width - root.strokeWidth / 2
    y: root.cutTopRight ? root.chamferSize : 0
    width: root.strokeWidth
    height: (root.cutBottomRight ? root.height - root.chamferSize : root.height) - y
  }
  // bottom
  Rectangle {
    visible: root.omitStrokeSide !== "bottom"
    color: root.strokeColor
    x: root.cutBottomLeft ? root.chamferSize : 0
    y: root.height - root.strokeWidth / 2
    width: (root.cutBottomRight ? root.width - root.chamferSize : root.width) - x
    height: root.strokeWidth
  }
  // left
  Rectangle {
    visible: root.omitStrokeSide !== "left"
    color: root.strokeColor
    x: -root.strokeWidth / 2
    y: root.cutTopLeft ? root.chamferSize : 0
    width: root.strokeWidth
    height: (root.cutBottomLeft ? root.height - root.chamferSize : root.height) - y
  }

  // Diagonal corners — each just 2 points, so none of them are ever the
  // "closing" segment of a longer chain (which was the leading but
  // ultimately disproven theory for the straight-edge bug above); kept
  // as Shape strokes since diagonals have always rendered fine here.
  Shape {
    anchors.fill: parent
    visible: root.cutTopLeft && root.omitStrokeSide !== "top" && root.omitStrokeSide !== "left"
    ShapePath {
      strokeColor: root.strokeColor
      strokeWidth: root.strokeWidth
      fillColor: "transparent"
      capStyle: ShapePath.SquareCap
      PathPolyline {
        path: [Qt.point(0, root.chamferSize), Qt.point(root.chamferSize, 0)]
      }
    }
  }
  Shape {
    anchors.fill: parent
    visible: root.cutTopRight && root.omitStrokeSide !== "top" && root.omitStrokeSide !== "right"
    ShapePath {
      strokeColor: root.strokeColor
      strokeWidth: root.strokeWidth
      fillColor: "transparent"
      capStyle: ShapePath.SquareCap
      PathPolyline {
        path: [Qt.point(root.width - root.chamferSize, 0), Qt.point(root.width, root.chamferSize)]
      }
    }
  }
  Shape {
    anchors.fill: parent
    visible: root.cutBottomRight && root.omitStrokeSide !== "bottom" && root.omitStrokeSide !== "right"
    ShapePath {
      strokeColor: root.strokeColor
      strokeWidth: root.strokeWidth
      fillColor: "transparent"
      capStyle: ShapePath.SquareCap
      PathPolyline {
        path: [Qt.point(root.width, root.height - root.chamferSize), Qt.point(root.width - root.chamferSize, root.height)]
      }
    }
  }
  Shape {
    anchors.fill: parent
    visible: root.cutBottomLeft && root.omitStrokeSide !== "bottom" && root.omitStrokeSide !== "left"
    ShapePath {
      strokeColor: root.strokeColor
      strokeWidth: root.strokeWidth
      fillColor: "transparent"
      capStyle: ShapePath.SquareCap
      PathPolyline {
        path: [Qt.point(root.chamferSize, root.height), Qt.point(0, root.height - root.chamferSize)]
      }
    }
  }
}
