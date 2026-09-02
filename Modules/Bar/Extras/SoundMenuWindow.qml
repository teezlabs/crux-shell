import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Modules.Bar.Extras

// Volume popup: default-output volume slider + mute toggle, and a list of
// available output devices to switch the default sink. Own primitives,
// same structural pattern as BluetoothMenuWindow.qml/WifiMenuWindow.qml.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  // Anchor to whichever edge the bar occupies, offset past its thickness +
  // float gap so the popup sits flush beside it rather than overlapping.
  readonly property string _barPos: Settings.isLoaded ? Settings.getBarPositionForScreen(root.targetScreen ? root.targetScreen.name : "") : "top"
  readonly property bool _barLeft: root._barPos === "left"
  readonly property bool _barRight: root._barPos === "right"
  readonly property bool _barBottom: root._barPos === "bottom"
  readonly property bool _barTop: !root._barLeft && !root._barRight && !root._barBottom
  readonly property real _barOffset: Settings.data.bar.thickness + Settings.data.bar.floatMargin

  // Bar-icon position (mapToItem into bar-local space) so the popup lines up with it; -1 = not set (e.g. IPC open),
  // falls back to a fixed corner inset. floatMargin converts bar-local coords into this popup's separate surface space.
  property point triggerPos: Qt.point(-1, -1)
  readonly property bool _hasTrigger: triggerPos.x >= 0
  readonly property real _triggerX: triggerPos.x + Settings.data.bar.floatMargin
  readonly property real _triggerY: triggerPos.y + Settings.data.bar.floatMargin

  readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
  readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
  readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

  readonly property var allSinks: {
    if (!Pipewire.ready || !Pipewire.nodes)
      return [];
    return Pipewire.nodes.values.filter(function (n) {
      return n && n.isSink && !n.isStream;
    });
  }

  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }

  function setVolume(pct) {
    if (!sink || !sink.audio)
      return;
    sink.audio.volume = pct / 100;
    if (pct > 0)
      sink.audio.muted = false;
  }

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
  WlrLayershell.namespace: "crux-sound-menu"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "sound"
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
    width: 300
    height: column.implicitHeight + 24

    // Cross-axis position (along the bar's own length): lines up with the
    // triggering icon when known, clamped on-screen; falls back to the old
    // fixed near-corner inset otherwise. Main-axis position (the gap
    // between the bar and the popup) always uses _barOffset, unchanged.
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
        text: "SOUND"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.weight: Font.DemiBold
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Item {
          width: 28
          height: 28

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: hoverMute.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer
            strokeColor: root.muted ? Color.alpha(Color.error, Tokens.destructiveBorderAlpha) : Color.outline
            strokeWidth: Tokens.borderModule
          }

          Text {
            anchors.centerIn: parent
            text: root.muted ? "×" : "))"
            color: root.muted ? Color.error : Color.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodySmSize
          }

          HoverHandler {
            id: hoverMute
            cursorShape: Qt.PointingHandCursor
          }

          TapHandler {
            onTapped: if (root.sink && root.sink.audio)
              root.sink.audio.muted = !root.sink.audio.muted
          }
        }

        SegMeter {
          Layout.fillWidth: true
          cellCount: Tokens.meterControlCenterCells
          cellHeight: Tokens.meterControlCenterCellHeight
          value: root.muted ? 0 : root.volume * 100
          interactive: true
          filledColor: Color.primary
          emptyColor: Color.surfaceContainerHigh
          onMoved: pct => root.setVolume(pct)
        }

        Text {
          text: root.muted ? "—" : Math.round(root.volume * 100) + "%"
          color: root.muted ? Color.error : Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
          Layout.preferredWidth: 34
        }
      }

      Text {
        text: "OUTPUT"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        Layout.topMargin: 4
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
          model: root.allSinks

          delegate: Rectangle {
            id: sinkRow
            required property var modelData
            Layout.fillWidth: true
            height: 32
            readonly property bool isDefault: root.sink && modelData.id === root.sink.id
            color: sinkRow.isDefault ? Color.primaryContainer : (hoverSink.hovered ? Color.surfaceContainerHigh : "transparent")

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8

              Text {
                text: sinkRow.isDefault ? "●" : "○"
                color: sinkRow.isDefault ? Color.primary : Color.labelText
                font.pixelSize: Tokens.bodySmSize
              }

              Text {
                text: sinkRow.modelData.description || sinkRow.modelData.name || ""
                color: sinkRow.isDefault ? Color.primaryContainerText : Color.surfaceText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.bodySmSize
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            HoverHandler {
              id: hoverSink
              cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
              onTapped: Pipewire.preferredDefaultAudioSink = sinkRow.modelData
            }
          }
        }
      }
    }
  }
}
