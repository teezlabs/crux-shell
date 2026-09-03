import QtQuick
import QtQuick.Shapes

// Chamfered-rectangle background, no rounded corners. Per-corner cut flags.
//
// Fill and stroke are both Shape geometry so they share one renderer and
// one anti-aliasing pass. The stroke runs on the outline offset inward by
// half its width, which is what makes it sit fully inside the item's
// bounds while still meeting the fill exactly — the fill polygon is drawn
// at the true outline underneath, so the stroke paints over its outer half
// and no fill can bleed past it.
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

  // Outline as a clockwise ring, offset inward by `inset`. A 45° chamfer
  // offset by d moves its endpoints along the edge by d*(sqrt(2)-1), so
  // the diagonal stays parallel to the un-inset one instead of drifting.
  function outline(inset: real): var {
    const d = inset;
    const c = root.chamferSize + d * (Math.SQRT2 - 1);
    const w = root.width;
    const h = root.height;
    const pts = [];
    const add = p => {
      const last = pts[pts.length - 1];
      // Consecutive duplicates appear wherever a corner isn't cut; they
      // give the miter join nothing to work with, so drop them.
      if (!last || Math.abs(last.x - p.x) > 0.001 || Math.abs(last.y - p.y) > 0.001)
        pts.push(p);
    };

    if (root.cutTopLeft) {
      add(Qt.point(d, d + c));
      add(Qt.point(d + c, d));
    } else {
      add(Qt.point(d, d));
    }
    if (root.cutTopRight) {
      add(Qt.point(w - d - c, d));
      add(Qt.point(w - d, d + c));
    } else {
      add(Qt.point(w - d, d));
    }
    if (root.cutBottomRight) {
      add(Qt.point(w - d, h - d - c));
      add(Qt.point(w - d - c, h - d));
    } else {
      add(Qt.point(w - d, h - d));
    }
    if (root.cutBottomLeft) {
      add(Qt.point(d + c, h - d));
      add(Qt.point(d, h - d - c));
    } else {
      add(Qt.point(d, h - d));
    }
    return pts;
  }

  // Index in the ring where each edge *ends*. Rotating the ring to start
  // there turns the closed loop into an open run that simply leaves out
  // the omitted edge, instead of drawing it and hiding it.
  function edgeStart(pts: var): int {
    const cuts = [root.cutTopLeft, root.cutTopRight, root.cutBottomRight, root.cutBottomLeft];
    const at = i => {
      let n = 0;
      for (let k = 0; k < i; k++)
        n += cuts[k] ? 2 : 1;
      return n;
    };
    switch (root.omitStrokeSide) {
    case "top":
      return at(1); // start at the top-right corner
    case "right":
      return at(2);
    case "bottom":
      return at(3);
    case "left":
      return 0;
    }
    return -1;
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    // Fill at the true outline, under the stroke.
    ShapePath {
      fillColor: root.fillColor
      strokeColor: "transparent"
      strokeWidth: 0
      PathPolyline {
        path: {
          const pts = root.outline(0);
          return pts.concat([pts[0]]);
        }
      }
    }

    // Stroke on the inset outline, closed when no edge is omitted.
    ShapePath {
      fillColor: "transparent"
      strokeColor: root.strokeColor
      strokeWidth: root.strokeWidth
      joinStyle: ShapePath.MiterJoin
      capStyle: ShapePath.FlatCap
      PathPolyline {
        path: {
          if (root.strokeWidth <= 0)
            return [];
          const pts = root.outline(root.strokeWidth / 2);
          const start = root.edgeStart(pts);
          if (start < 0)
            return pts.concat([pts[0]]);
          const n = pts.length;
          const run = [];
          for (let i = 0; i < n; i++)
            run.push(pts[(start + i) % n]);
          return run;
        }
      }
    }
  }
}
