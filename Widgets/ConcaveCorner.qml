import QtQuick
import QtQuick.Shapes
import qs.Commons

// The fillet that joins a panel to the bar it grew out of: a square of
// panel colour with its far corner cut off at 45°, so the junction reads
// as one continuous surface instead of a box sitting next to a strip.
//
// Straight, not an arc. Crux's whole language is chamfers with an explicit
// no-radius rule, and this was the last curve left in the shell — a
// quarter-disc here read as a different material from the chamfered card
// it was flaring out of.
//
// `corner` names which way it faces, as a compass point for the sharp
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
  // Optional outline along the diagonal only — the two legs sit flush
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

      // Sharp corner at the origin, far corner chamfered off.
      startX: 0
      startY: 0
      PathLine {
        x: root.size
        y: 0
      }
      PathLine {
        x: 0
        y: root.size
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
      PathLine {
        x: 0
        y: root.size
      }
    }
  }
}
