import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Modules.Bar.Extras

// Brightness popup slider; `controller` (the Brightness.qml widget) owns the actual brightnessctl state.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen
  property var controller: null

  readonly property string _barPos: Settings.isLoaded ? Settings.getBarPositionForScreen(root.targetScreen ? root.targetScreen.name : "") : "top"
  readonly property bool _barLeft: root._barPos === "left"
  readonly property bool _barRight: root._barPos === "right"
  readonly property bool _barBottom: root._barPos === "bottom"
  readonly property bool _barTop: !root._barLeft && !root._barRight && !root._barBottom
  readonly property real _barOffset: Settings.data.bar.thickness + Settings.data.bar.floatMargin

  property point triggerPos: Qt.point(-1, -1)
  readonly property bool _hasTrigger: triggerPos.x >= 0
  readonly property real _triggerX: triggerPos.x + Settings.data.bar.floatMargin
  readonly property real _triggerY: triggerPos.y + Settings.data.bar.floatMargin

  function toggle() {
    visible = !visible;
  }

  visible: false
  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-brightness-menu"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "brightness"
    function toggle() {
      root.toggle();
    }
    function open() {
      root.visible = true;
    }
    function close() {
      root.visible = false;
    }
  }

  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.visible = false
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.visible = false
  }

  Item {
    id: card
    width: 260
    height: column.implicitHeight + 24

    readonly property real _crossFallback: 12
    readonly property real _crossPos: {
      if (root._barLeft || root._barRight)
        return root._hasTrigger ? Math.max(8, Math.min(root._triggerY, root.height - card.height - 8)) : _crossFallback;
      return root._hasTrigger ? Math.max(8, Math.min(root._triggerX, root.width - card.width - 8)) : root.width - card.width - _crossFallback;
    }

    x: root._barLeft ? root._barOffset : (root._barRight ? root.width - card.width - root._barOffset : card._crossPos)
    y: root._barBottom ? root.height - card.height - root._barOffset : (root._barLeft || root._barRight ? card._crossPos : root._barOffset)

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      // Flush against the bar, so cut only the two corners on the far
      // side from it -- the near side reads as growing out of the bar
      // instead of floating as a fully separate chamfered card.
      cutTopLeft: root._barBottom || root._barRight
      cutTopRight: root._barBottom || root._barLeft
      cutBottomLeft: root._barTop || root._barRight
      cutBottomRight: root._barTop || root._barLeft
      omitStrokeSide: root._barBottom ? "bottom" : (root._barLeft ? "left" : (root._barRight ? "right" : "top"))
      fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
      strokeColor: Color.outline
      strokeWidth: Tokens.borderPanel
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      id: column
      anchors.fill: parent
      anchors.margins: 14
      spacing: 12

      Text {
        text: "BRIGHTNESS"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.weight: Font.DemiBold
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        SegMeter {
          Layout.fillWidth: true
          cellCount: Tokens.meterControlCenterCells
          cellHeight: Tokens.meterControlCenterCellHeight
          value: root.controller ? root.controller.percent : 0
          interactive: true
          filledColor: Color.primary
          emptyColor: Color.surfaceContainerHigh
          onMoved: pct => {
            if (root.controller)
              root.controller.setBrightness(pct / 100);
          }
        }

        Text {
          text: (root.controller ? root.controller.percent : 0) + "%"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
          Layout.preferredWidth: 34
        }
      }

      Text {
        visible: !root.controller || !root.controller.available
        text: "No internal backlight device detected."
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.captionSize
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
    }
  }
}
