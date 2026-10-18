import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import qs.Commons

// Chamfered rectangle with per-corner cuts; fill and stroke are one Shape (docs/design-notes.md, "Chamfer geometry").
Item {
  id: root

  property int chamferSize: 8
  property bool cutTopLeft: false
  property bool cutTopRight: false
  property bool cutBottomLeft: false
  property bool cutBottomRight: false
  property color fillColor: "transparent"
  property color strokeColor: "transparent"
  // Eases between colours so hovers settle and a retheme cross-fades; false where a colour must track instantly.
  property bool animateColor: true

  // Opt-in shadow cast by this outline and masked out under the shape, since panels are translucent.
  property bool shadow: false
  property real shadowBlur: Tokens.shadowBlurPanel
  property real shadowOpacity: Tokens.shadowOpacityPanel
  property real shadowOffset: Tokens.shadowOffsetPanel

  // Lit top edge, the other half of elevation (docs/look-and-feel.md, "Depth").
  property bool rimLight: false
  property real rimOpacity: Tokens.rimOpacityPanel
  property real strokeWidth: 0
  // Skip the stroke on one edge ("top"/"right"/"bottom"/"left"); the fill still covers it.
  property string omitStrokeSide: ""
  // Pulls both open stroke ends back so they meet a ConcaveCorner's tangent instead of forming a Y.
  property real strokeTrim: 0

  // Clockwise ring inset by `inset`; chamfer endpoints shift by inset*(sqrt(2)-1) to keep the diagonal parallel.
  function outline(inset: real): var {
    const d = inset;
    const c = root.chamferSize + d * (Math.SQRT2 - 1);
    const w = root.width;
    const h = root.height;
    const pts = [];
    const add = p => {
      const last = pts[pts.length - 1];
      // Uncut corners produce duplicate points, which break the miter join.
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

  // Index where each edge ends; starting the ring there leaves the omitted edge out of the run.
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

  // Flat part of the top edge only, so it never overhangs a chamfer.
  Rectangle {
    visible: root.rimLight
    // On the top stroke, not under it, which read as a doubled border.
    height: Math.max(1, root.strokeWidth)
    y: 0
    x: (root.cutTopLeft ? root.chamferSize : 0) + root.strokeWidth
    width: Math.max(0, root.width - x - (root.cutTopRight ? root.chamferSize : 0) - root.strokeWidth)
    color: Colors.alpha(Colors.surfaceText, root.rimOpacity)
    z: 1
  }

  // Moves a toward b by dist, never past the midpoint.
  function towards(a: var, b: var, dist: real): var {
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const len = Math.sqrt(dx * dx + dy * dy);
    if (len <= 0.001)
      return a;
    const t = Math.min(dist, len / 2) / len;
    return Qt.point(a.x + dx * t, a.y + dy * t);
  }

  // Silhouette used only as the shadow caster and its mask.
  Shape {
    id: silhouette
    anchors.fill: parent
    visible: false
    layer.enabled: root.shadow
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      fillColor: "black"
      strokeColor: "transparent"
      strokeWidth: 0
      PathPolyline {
        path: {
          const pts = root.outline(0);
          return pts.concat([pts[0]]);
        }
      }
    }
  }

  MultiEffect {
    anchors.fill: parent
    source: silhouette
    visible: root.shadow
    shadowEnabled: root.shadow
    blurMax: root.shadowBlur
    shadowColor: Tokens.shadowColor
    shadowOpacity: root.shadowOpacity
    shadowVerticalOffset: root.shadowOffset
    shadowHorizontalOffset: 0
    // Cuts the caster back out, leaving only what falls outside the shape.
    maskEnabled: true
    maskSource: silhouette
    maskInverted: true
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    // Fill at the true outline, under the stroke.
    ShapePath {
      fillColor: root.fillColor
      strokeColor: "transparent"

      Behavior on fillColor {
        enabled: root.animateColor
        ColorAnimation {
          duration: Tokens.durationColor
          easing.type: Tokens.easingColor
        }
      }
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

      Behavior on strokeColor {
        enabled: root.animateColor
        ColorAnimation {
          duration: Tokens.durationColor
          easing.type: Tokens.easingColor
        }
      }
      strokeWidth: root.strokeWidth
      joinStyle: ShapePath.MiterJoin
      // Square caps carry an open run's free ends out to the omitted edge.
      capStyle: ShapePath.SquareCap
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
          if (root.strokeTrim > 0 && run.length >= 2) {
            run[0] = root.towards(run[0], run[1], root.strokeTrim);
            run[run.length - 1] = root.towards(run[run.length - 1], run[run.length - 2], root.strokeTrim);
          }
          return run;
        }
      }
    }
  }
}
