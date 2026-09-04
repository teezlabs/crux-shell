import QtQuick
import QtQuick.Shapes
import qs.Commons

// The fillet that joins a panel to the bar it grew out of: a square of
// panel colour with a quarter-disc bitten out of the far corner, so the
// junction reads as one continuous surface instead of a box sitting next
// to a strip.
//
// `corner` names which way it curves, as a compass point for the sharp
// corner — the one that touches the junction.
Item {
  id: root

  enum Corner {
    TopLeft,
    TopRight,
    BottomRight,
    BottomLeft
  }

  property int corner: ConcaveCorner.Corner.TopLeft
  property color fillColor: Color.surface
  // Optional outline along the arc only — the two straight legs sit flush
  // against the panel and the bar, so stroking them would draw a seam
  // through the very junction this shape exists to hide.
  property color strokeColor: "transparent"
  property real strokeWidth: 0
  property real size: Tokens.chamferPanel

  implicitWidth: root.size
  implicitHeight: root.size
  width: implicitWidth
  height: implicitHeight

  // Rotating one shape beats writing four: the geometry is the same corner
  // every time, just facing a different way.
  readonly property int spin: {
    switch (root.corner) {
    case ConcaveCorner.Corner.TopRight:
      return 90;
    case ConcaveCorner.Corner.BottomRight:
      return 180;
    case ConcaveCorner.Corner.BottomLeft:
      return 270;
    }
    return 0;
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    rotation: root.spin
    transformOrigin: Item.Center

    ShapePath {
      fillColor: root.fillColor
      strokeColor: "transparent"
      strokeWidth: 0

      // Sharp corner at the origin, arc bulging toward it.
      startX: 0
      startY: 0
      PathLine {
        x: root.size
        y: 0
      }
      PathArc {
        x: 0
        y: root.size
        radiusX: root.size
        radiusY: root.size
        direction: PathArc.Counterclockwise
      }
      PathLine {
        x: 0
        y: 0
      }
    }

    ShapePath {
      fillColor: "transparent"
      strokeColor: root.strokeColor
      strokeWidth: root.strokeWidth
      capStyle: ShapePath.FlatCap

      startX: root.size
      startY: 0
      PathArc {
        x: 0
        y: root.size
        radiusX: root.size
        radiusY: root.size
        direction: PathArc.Counterclockwise
      }
    }
  }
}
