import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs.Commons

// Volume OSD: shows briefly whenever the default sink's volume or mute state
// changes, regardless of what caused it (physical keys, another app, this
// shell) — reacts to real Pipewire state rather than being IPC-triggered,
// so it needs no keybind wiring to be testable. Node reactivity pattern
// (PwObjectTracker + Connections on sink.audio) ported from noctalia's
// Services/Media/AudioService.qml — Pipewire nodes don't reliably push
// property updates unless tracked.
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
    opened = true;
    hideTimer.restart();
  }

  Timer {
    id: hideTimer
    interval: 1200
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

  Rectangle {
    width: 220
    height: 56
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 90
    radius: 2
    color: "#1e1e2e"
    border.color: "#45475a"
    border.width: 1
    opacity: root.opened ? 1 : 0
    Behavior on opacity {
      NumberAnimation {
        duration: 120
      }
    }

    Row {
      anchors.fill: parent
      anchors.margins: 14
      spacing: 12

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.muted ? "MUTE" : "VOL"
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: 11
        color: root.muted ? "#f38ba8" : "#89b4fa"
      }

      Rectangle {
        width: 120
        height: 6
        anchors.verticalCenter: parent.verticalCenter
        radius: 1
        color: "#313244"

        Rectangle {
          width: parent.width * Math.min(1, root.muted ? 0 : root.volume)
          height: parent.height
          radius: 1
          color: "#89b4fa"
          Behavior on width {
            NumberAnimation {
              duration: 100
            }
          }
        }
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round((root.muted ? 0 : root.volume) * 100) + "%"
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: 12
        color: "#cdd6f4"
      }
    }
  }
}
