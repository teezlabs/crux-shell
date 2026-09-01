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

  readonly property var _points: {
    var w = root.width;
    var h = root.height;
    var c = root.chamferSize;
    var pts = [];
    // Top-left corner
    pts.push(root.cutTopLeft ? Qt.point(c, 0) : Qt.point(0, 0));
    // Top-right corner
    pts.push(root.cutTopRight ? Qt.point(w - c, 0) : Qt.point(w, 0));
    if (root.cutTopRight)
      pts.push(Qt.point(w, c));
    // Bottom-right corner
    pts.push(root.cutBottomRight ? Qt.point(w, h - c) : Qt.point(w, h));
    if (root.cutBottomRight)
      pts.push(Qt.point(w - c, h));
    // Bottom-left corner
    pts.push(root.cutBottomLeft ? Qt.point(c, h) : Qt.point(0, h));
    if (root.cutBottomLeft)
      pts.push(Qt.point(0, h - c));
    // Close back to the start
    if (root.cutTopLeft)
      pts.push(Qt.point(0, c));
    pts.push(pts[0]);
    return pts;
  }

  preferredRendererType: Shape.GeometryRenderer

  ShapePath {
    fillColor: root.fillColor
    strokeColor: root.strokeColor
    strokeWidth: root.strokeWidth
    capStyle: ShapePath.SquareCap
    joinStyle: ShapePath.MiterJoin

    PathPolyline {
      path: root._points
    }
  }
}
