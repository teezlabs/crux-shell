import QtQuick
import QtQuick.Layouts
import qs.Commons

// Chamfered checkbox with an optional label/description to its right.
RowLayout {
  id: root

  property string label: ""
  property string description: ""
  property bool checked: false
  property real boxSize: 16

  signal toggled(bool checked)

  spacing: 8
  opacity: enabled ? 1.0 : 0.5

  Item {
    Layout.preferredWidth: root.boxSize
    Layout.preferredHeight: root.boxSize
    Layout.alignment: Qt.AlignTop

    Chamfer {
      anchors.fill: parent
      chamferSize: 4
      cutTopRight: true
      cutBottomLeft: true
      fillColor: root.checked ? Color.primaryContainer : Color.surfaceContainerHigh
      strokeColor: root.checked ? Color.primary : Color.outline
      strokeWidth: Tokens.borderModule
    }

    // Tick drawn geometrically — no glyph font dependency.
    Canvas {
      anchors.fill: parent
      visible: root.checked
      readonly property color drawColor: Color.primary
      onDrawColorChanged: requestPaint()
      onVisibleChanged: requestPaint()
      onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = drawColor;
        ctx.lineWidth = 2;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.beginPath();
        ctx.moveTo(width * 0.24, height * 0.52);
        ctx.lineTo(width * 0.44, height * 0.72);
        ctx.lineTo(width * 0.78, height * 0.28);
        ctx.stroke();
      }
    }
  }

  NLabel {
    Layout.fillWidth: true
    label: root.label
    description: root.description
    visible: root.label !== "" || root.description !== ""
  }

  HoverHandler {
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    enabled: root.enabled
    onTapped: root.toggled(!root.checked)
  }
}
