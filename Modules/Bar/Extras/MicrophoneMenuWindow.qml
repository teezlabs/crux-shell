import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Modules.Bar.Extras

// Microphone popup: default-input volume slider + mute toggle, and a list
// of available input devices to switch the default source. Exact structural
// mirror of SoundMenuWindow.qml, just bound to defaultAudioSource/allSources.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property string _barPos: Settings.isLoaded ? Settings.getBarPositionForScreen(root.targetScreen ? root.targetScreen.name : "") : "top"
  readonly property bool _barLeft: root._barPos === "left"
  readonly property bool _barRight: root._barPos === "right"
  readonly property bool _barBottom: root._barPos === "bottom"
  readonly property real _barOffset: Settings.data.bar.thickness + Settings.data.bar.floatMargin * 2 + 20

  property point triggerPos: Qt.point(-1, -1)
  readonly property bool _hasTrigger: triggerPos.x >= 0
  readonly property real _triggerX: triggerPos.x + Settings.data.bar.floatMargin
  readonly property real _triggerY: triggerPos.y + Settings.data.bar.floatMargin

  readonly property var source: Pipewire.ready ? Pipewire.defaultAudioSource : null
  readonly property real volume: source && source.audio ? source.audio.volume : 0
  readonly property bool muted: source && source.audio ? source.audio.muted : false

  readonly property var allSources: {
    if (!Pipewire.ready || !Pipewire.nodes)
      return [];
    return Pipewire.nodes.values.filter(function (n) {
      return n && !n.isSink && !n.isStream && n.audio;
    });
  }

  PwObjectTracker {
    objects: root.source ? [root.source] : []
  }

  function setVolume(pct) {
    if (!source || !source.audio)
      return;
    source.audio.volume = pct / 100;
    if (pct > 0)
      source.audio.muted = false;
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
  WlrLayershell.namespace: "crux-microphone-menu"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "microphone"
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
      cutTopRight: true
      cutBottomLeft: true
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
        text: "MICROPHONE"
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
            onTapped: if (root.source && root.source.audio)
              root.source.audio.muted = !root.source.audio.muted
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
        text: "INPUT"
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
          model: root.allSources

          delegate: Rectangle {
            id: sourceRow
            required property var modelData
            Layout.fillWidth: true
            height: 32
            readonly property bool isDefault: root.source && modelData.id === root.source.id
            color: sourceRow.isDefault ? Color.primaryContainer : (hoverSource.hovered ? Color.surfaceContainerHigh : "transparent")

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8

              Text {
                text: sourceRow.isDefault ? "●" : "○"
                color: sourceRow.isDefault ? Color.primary : Color.labelText
                font.pixelSize: Tokens.bodySmSize
              }

              Text {
                text: sourceRow.modelData.description || sourceRow.modelData.name || ""
                color: sourceRow.isDefault ? Color.primaryContainerText : Color.surfaceText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.bodySmSize
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            HoverHandler {
              id: hoverSource
              cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
              onTapped: Pipewire.preferredDefaultAudioSource = sourceRow.modelData
            }
          }
        }

        Text {
          visible: root.allSources.length === 0
          text: "No input devices found."
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
        }
      }
    }
  }
}
