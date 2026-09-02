import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs.Commons
import qs.Modules.Bar.Extras

// Battery detail popup: percent/status, health, and a power-profile switcher via PowerProfiles (no-op if the daemon isn't running).
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen
  // The Battery.qml widget instance that opened this popup — read its
  // already-computed percent/charging/device properties directly rather
  // than re-deriving them here.
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

  readonly property var device: controller ? controller.device : null
  readonly property bool healthKnown: !!device && device.healthSupported === true

  readonly property var profileOptions: [
    {
      "key": PowerProfile.PowerSaver,
      "label": "SAVER"
    },
    {
      "key": PowerProfile.Balanced,
      "label": "BALANCED"
    },
    {
      "key": PowerProfile.Performance,
      "label": "PERF"
    }
  ]

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
  WlrLayershell.namespace: "crux-battery-menu"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "battery"
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
    width: 280
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
        text: "BATTERY"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.weight: Font.DemiBold
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Text {
          text: (root.controller ? root.controller.percent : 0) + "%"
          color: root.controller ? root.controller.statusColor : Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.titleSize
          font.weight: Font.Light
        }

        Text {
          text: root.controller ? root.controller.statusText : ""
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
          Layout.fillWidth: true
          wrapMode: Text.WordWrap
        }
      }

      SegMeter {
        Layout.fillWidth: true
        cellCount: Tokens.meterControlCenterCells
        cellHeight: Tokens.meterControlCenterCellHeight
        value: root.controller ? root.controller.percent : 0
        filledColor: root.controller ? root.controller.statusColor : Color.primary
        emptyColor: Color.surfaceContainerHigh
      }

      RowLayout {
        Layout.fillWidth: true
        visible: root.healthKnown
        spacing: 6

        Text {
          text: "HEALTH"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
        Item {
          Layout.fillWidth: true
        }
        Text {
          text: root.healthKnown ? Math.round(root.device.healthPercentage) + "%" : ""
          color: Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
        }
      }

      Text {
        text: "POWER PROFILE"
        visible: Settings.data.battery.showPowerProfile
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        Layout.topMargin: 4
      }

      RowLayout {
        Layout.fillWidth: true
        visible: Settings.data.battery.showPowerProfile
        spacing: 6

        Repeater {
          model: root.profileOptions

          delegate: Item {
            id: profileTile
            required property var modelData
            readonly property bool active: PowerProfiles.profile === modelData.key
            Layout.fillWidth: true
            height: 26

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: profileTile.active ? Color.primaryContainer : (profileHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer)
              strokeColor: profileTile.active ? Color.primary : Color.outline
              strokeWidth: Tokens.borderModule
            }

            Text {
              anchors.centerIn: parent
              text: profileTile.modelData.label
              color: profileTile.active ? Color.primaryContainerText : Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
              font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
            }

            HoverHandler {
              id: profileHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: PowerProfiles.profile = profileTile.modelData.key
            }
          }
        }
      }
    }
  }
}
