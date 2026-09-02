import QtQuick
import QtQuick.Shapes

// Chamfered-rectangle background, no rounded corners. Per-corner cut flags; PathPolyline since vertex count varies with cuts.
Shape {
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

  // Each corner as its own [incoming, outgoing] pair — the two points
  // where the path enters and leaves that corner. Equal (a single real
  // point, repeated) when the corner isn't cut, so every corner has the
  // same 2-element shape regardless — that uniformity is what lets the
  // stroke path below start/end at any corner, not just always close the
  // loop back at top-left.
  readonly property var _tl: root.cutTopLeft ? [Qt.point(0, root.chamferSize), Qt.point(root.chamferSize, 0)] : [Qt.point(0, 0), Qt.point(0, 0)]
  readonly property var _tr: root.cutTopRight ? [Qt.point(root.width - root.chamferSize, 0), Qt.point(root.width, root.chamferSize)] : [Qt.point(root.width, 0), Qt.point(root.width, 0)]
  readonly property var _br: root.cutBottomRight ? [Qt.point(root.width, root.height - root.chamferSize), Qt.point(root.width - root.chamferSize, root.height)] : [Qt.point(root.width, root.height), Qt.point(root.width, root.height)]
  readonly property var _bl: root.cutBottomLeft ? [Qt.point(root.chamferSize, root.height), Qt.point(0, root.height - root.chamferSize)] : [Qt.point(0, root.height), Qt.point(0, root.height)]

  readonly property var _fillPoints: {
    var pts = [].concat(root._tl, root._tr, root._br, root._bl);
    pts.push(pts[0]);
    return pts;
  }

  // An open path skipping whichever edge omitStrokeSide names, by starting
  // right after that edge's corner and ending right before it — every
  // corner still emits both its own points, only the one connecting
  // segment between the two named corners is left undrawn. With
  // omitStrokeSide "", it's the full loop instead — re-tracing the first
  // segment once more, since PathPolyline doesn't flag a repeated start
  // point as a genuinely closed loop for stroke-joining purposes: the
  // shared vertex got two independent line caps instead of one corner
  // join, a visible gap once strokeWidth is actually non-zero (confirmed
  // on the floating bar's outline border). Duplicating the segment gives
  // that vertex a real second neighbor to join against; the overlap
  // redraws identical pixels, so it's invisible otherwise.
  readonly property var _strokePoints: {
    switch (root.omitStrokeSide) {
    case "top":
      return [].concat(root._tr, root._br, root._bl, root._tl);
    case "right":
      return [].concat(root._br, root._bl, root._tl, root._tr);
    case "bottom":
      return [].concat(root._bl, root._tl, root._tr, root._br);
    case "left":
      return [].concat(root._tl, root._tr, root._br, root._bl);
    default:
      var pts = [].concat(root._tl, root._tr, root._br, root._bl);
      pts.push(pts[0]);
      pts.push(pts[1]);
      return pts;
    }
  }

  ShapePath {
    fillColor: root.fillColor
    strokeColor: "transparent"

    PathPolyline {
      path: root._fillPoints
    }
  }

  ShapePath {
    fillColor: "transparent"
    strokeColor: root.strokeColor
    strokeWidth: root.strokeWidth
    capStyle: ShapePath.SquareCap
    // Bevel, not miter — a miter join spikes outward past the shape at the
    // chamfer's sharp vertex once strokeWidth is actually non-zero
    // (confirmed: a visible jagged corner artifact on the floating bar's
    // outline border, the first real user of a non-transparent stroke).
    joinStyle: ShapePath.BevelJoin

    PathPolyline {
      path: root._strokePoints
    }
  }
}
