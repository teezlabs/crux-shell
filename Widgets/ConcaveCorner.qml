import QtQuick
import QtQuick.Shapes
import qs.Commons

// Fillet joining a panel to the bar it grew from: a square with its far corner cut at 45° (docs/design-notes.md, "The drawer fillet").
// `corner` names the sharp corner touching the junction, as a compass point.
Item {
  id: root

  enum Corner {
    TopLeft,
    TopRight,
    BottomRight,
    BottomLeft
  }

  property int corner: ConcaveCorner.Corner.TopLeft
  property color fillColor: Colors.surface
  // Diagonal only; stroking the legs would draw a seam through the junction.
  property color strokeColor: "transparent"
  property real strokeWidth: 0
  property real size: Tokens.chamferPanel

  implicitWidth: root.size
  implicitHeight: root.size
  width: implicitWidth
  height: implicitHeight

  // One shape, rotated for each corner.
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
