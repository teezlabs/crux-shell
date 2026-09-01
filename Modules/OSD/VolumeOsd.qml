import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Modules.Bar.Extras

// Volume OSD: shows briefly on any default-sink volume/mute change, from
// any source. Reacts to real Pipewire state (PwObjectTracker required —
// nodes don't reliably push updates unless tracked), not IPC-triggered.
// Uses the app's standard two-opposite-corner chamfer, not spec §6.5's
// all-four-corners text — confirmed deliberate, for visual consistency.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
  readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
  readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }

  Connections {
    target: root.sink ? root.sink.audio : null
    function onVolumeChanged() {
      root.show();
    }
    function onMutedChanged() {
      root.show();
    }
  }

  property bool opened: false

  function show() {
    if (!Settings.data.osd.enabled)
      return;
    opened = true;
    hideTimer.restart();
  }

  Timer {
    id: hideTimer
    interval: Settings.data.osd.durationMs
    onTriggered: root.opened = false
  }

  visible: opened
  color: "transparent"

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  WlrLayershell.namespace: "crux-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  // Visual only — never intercepts clicks meant for whatever's underneath.
  mask: Region {}

  Item {
    id: card
    width: 296
    height: 44
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: Settings.data.osd.position === "top" ? parent.top : undefined
    anchors.bottom: Settings.data.osd.position === "bottom" ? parent.bottom : undefined
    anchors.verticalCenter: Settings.data.osd.position === "center" ? parent.verticalCenter : undefined
    anchors.topMargin: 60
    anchors.bottomMargin: 60
    opacity: root.opened ? 1 : 0
    Behavior on opacity {
      NumberAnimation {
        duration: Tokens.durationOsdFade
        easing.type: Tokens.easingOsdFade
      }
    }

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferModule
      cutTopLeft: false
      cutTopRight: true
      cutBottomLeft: true
      cutBottomRight: false
      fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
      strokeColor: root.muted ? Color.alpha(Color.error, Tokens.destructiveBorderAlpha) : Color.outline
      strokeWidth: Tokens.borderPanel
    }

    Row {
      anchors.fill: parent
      anchors.margins: 14
      spacing: 12

      Text {
        width: 40
        text: root.muted ? "MUTE" : "VOL"
        color: root.muted ? Color.error : Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelSize
        font.weight: Font.DemiBold
        font.letterSpacing: Tokens.labelSize * Tokens.labelTracking
      }

      SegMeter {
        width: 168
        cellCount: Tokens.meterOsdCells
        cellHeight: Tokens.meterOsdCellHeight
        value: root.muted ? 0 : root.volume * 100
        filledColor: Color.primary
        emptyColor: Color.surfaceContainerHigh
      }

      Text {
        text: root.muted ? "—" : String(Math.round(root.volume * 100))
        color: root.muted ? Color.labelText : Color.primary
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodyLgSize
        font.weight: Font.DemiBold
      }
    }
  }
}
