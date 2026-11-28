import QtQuick
import qs.Commons
import qs.Widgets

// A desktop widget's frame: placement and background from Settings.data.desktopWidgets[<key>X/Y/Scale/Card], and in edit mode an
// outline, a move drag and a corner resize handle, both snapping to the grid.
Item {
  id: root

  // Settings prefix: "weather" reads weatherX, weatherY, weatherScale.
  required property string key
  property string label: ""
  // The full-screen item the card is clamped to.
  required property Item area
  property real gridSize: 30
  property real defaultX: 0
  property real defaultY: 0
  // Size of the content before scaling; the card adds `padding` on every side.
  property real contentWidth: 200
  property real contentHeight: 100
  property real padding: 12
  property bool cutTopLeft: false
  property bool cutTopRight: true
  property bool cutBottomLeft: true
  property bool cutBottomRight: false

  default property alias content: body.data

  readonly property var store: Settings.data.desktopWidgets
  readonly property real savedX: root.store[root.key + "X"]
  readonly property real savedY: root.store[root.key + "Y"]
  readonly property real savedScale: root.store[root.key + "Scale"] > 0 ? root.store[root.key + "Scale"] : 1
  readonly property real cardScale: resize.active ? resize.liveScale : root.savedScale
  readonly property bool snapping: Settings.data.desktopWidgets.gridSnap
  readonly property bool background: root.store[root.key + "Card"] !== false

  width: frame.width * root.cardScale
  height: frame.height * root.cardScale

  function snap(v) {
    return root.snapping ? Math.round(v / root.gridSize) * root.gridSize : v;
  }
  function clampX(v) {
    return Math.max(0, Math.min(v, root.area.width - root.width));
  }
  function clampY(v) {
    return Math.max(0, Math.min(v, root.area.height - root.height));
  }

  x: move.active ? root.clampX(move.startX + move.activeTranslation.x) : root.clampX(root.savedX >= 0 ? root.savedX : root.defaultX)
  y: move.active ? root.clampY(move.startY + move.activeTranslation.y) : root.clampY(root.savedY >= 0 ? root.savedY : root.defaultY)

  Item {
    id: frame
    width: root.contentWidth + root.padding * 2
    height: root.contentHeight + root.padding * 2
    scale: root.cardScale
    transformOrigin: Item.TopLeft

    Chamfer {
      visible: root.background
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutTopLeft: root.cutTopLeft
      cutTopRight: root.cutTopRight
      cutBottomLeft: root.cutBottomLeft
      cutBottomRight: root.cutBottomRight
      fillColor: Colors.alpha(Colors.surface, Tokens.panelOpacity)
      strokeColor: Colors.outline
      strokeWidth: Tokens.borderPanel
    }

    Item {
      id: body
      x: root.padding
      y: root.padding
      width: root.contentWidth
      height: root.contentHeight
    }
  }

  // ---- Edit mode: covers the content so its own controls don't take the drag ----
  Item {
    id: editLayer
    anchors.fill: parent
    visible: DesktopEdit.active
    z: 10

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutTopLeft: root.cutTopLeft
      cutTopRight: root.cutTopRight
      cutBottomLeft: root.cutBottomLeft
      cutBottomRight: root.cutBottomRight
      fillColor: Colors.alpha(Colors.primary, move.active || moveHover.hovered ? 0.12 : 0.05)
      strokeColor: Colors.primary
      strokeWidth: Tokens.borderMarker
    }

    NText {
      visible: root.label !== ""
      x: Tokens.spaceMd
      y: -height - Tokens.spaceXs
      text: root.label + "  ·  " + Math.round(root.cardScale * 100) + "%"
      tracking: true
      size: NText.Size.LabelXs
      font.weight: Font.DemiBold
      color: Colors.primary
    }

    HoverHandler {
      id: moveHover
      cursorShape: move.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
    }
    DragHandler {
      id: move
      target: null
      property real startX: 0
      property real startY: 0
      onActiveChanged: {
        if (active) {
          startX = root.x;
          startY = root.y;
          return;
        }
        root.store[root.key + "X"] = root.clampX(root.snap(startX + activeTranslation.x));
        root.store[root.key + "Y"] = root.clampY(root.snap(startY + activeTranslation.y));
      }
    }

    // Bottom-right resize handle.
    Rectangle {
      id: grip
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      width: 14
      height: 14
      color: resize.active || gripHover.hovered ? Colors.primary : Colors.alpha(Colors.primary, 0.6)

      HoverHandler {
        id: gripHover
        cursorShape: Qt.SizeFDiagCursor
      }
      DragHandler {
        id: resize
        target: null
        property real startScale: 1
        property real startWidth: 1
        readonly property real liveScale: Math.max(0.5, Math.min(4, startScale * (startWidth + activeTranslation.x) / startWidth))
        onActiveChanged: {
          if (active) {
            startScale = root.savedScale;
            startWidth = Math.max(1, root.width);
            return;
          }
          let s = liveScale;
          // Snap the scaled width to whole grid cells.
          if (root.snapping) {
            const cells = Math.max(1, Math.round(frame.width * s / root.gridSize));
            s = Math.max(0.5, Math.min(4, cells * root.gridSize / frame.width));
          }
          root.store[root.key + "Scale"] = Math.round(s * 1000) / 1000;
        }
      }
    }
  }
}
