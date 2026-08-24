import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Modules.Bar.Extras
import qs.Commons

// Volume control on the bar: click opens the output/volume popup, scroll
// up/down adjusts volume directly, right-click toggles mute. Pipewire node
// reactivity (PwObjectTracker) matches the same pattern already used in
// Modules/OSD/VolumeOsd.qml — Pipewire nodes don't reliably push property
// updates unless tracked.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
  readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
  readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }

  implicitWidth: 32
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  SoundMenuWindow {
    id: menu
    targetScreen: root.screen
  }

  function _setVolume(v) {
    if (!root.sink || !root.sink.audio)
      return;
    root.sink.audio.volume = Math.max(0, Math.min(1, v));
    if (root.sink.audio.muted && v > 0)
      root.sink.audio.muted = false;
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: 4
    radius: Style.radiusXXS
    color: hoverHandler.hovered ? Color.alpha(Color.mPrimary, 0.16) : "transparent"
    border.color: Color.alpha(Color.mPrimary, 0.55)
    border.width: hoverHandler.hovered ? 1 : 0
    scale: hoverHandler.hovered ? 1.1 : 1.0
    Behavior on color {
      ColorAnimation {
        duration: Style.animationFast
      }
    }
    Behavior on scale {
      NumberAnimation {
        duration: Style.animationFast
        easing.type: Easing.OutBack
      }
    }

    // Speaker + volume-wave glyph, geometric (no font/emoji glyph
    // dependency) — a slash overlay when muted, arc count following volume.
    Canvas {
      id: canvas
      anchors.centerIn: parent
      width: 18
      height: 16
      readonly property color drawColor: root.muted ? Color.mOutline : Color.mOnSurface
      readonly property real vol: root.volume
      readonly property bool isMuted: root.muted
      onDrawColorChanged: requestPaint()
      onVolChanged: requestPaint()
      onIsMutedChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = drawColor;
        ctx.fillStyle = drawColor;
        ctx.lineWidth = 1.4;
        ctx.lineCap = "round";

        // Speaker body: a small square plus a trapezoid horn.
        ctx.beginPath();
        ctx.moveTo(0, 5);
        ctx.lineTo(3, 5);
        ctx.lineTo(7, 1.5);
        ctx.lineTo(7, 14.5);
        ctx.lineTo(3, 11);
        ctx.lineTo(0, 11);
        ctx.closePath();
        ctx.fill();

        if (isMuted) {
          ctx.beginPath();
          ctx.moveTo(10, 3);
          ctx.lineTo(17, 13);
          ctx.stroke();
          return;
        }

        // Volume arcs — 1 to 3 depending on level.
        var arcs = vol <= 0 ? 0 : (vol < 0.34 ? 1 : (vol < 0.67 ? 2 : 3));
        for (var i = 0; i < arcs; i++) {
          var r = 3 + i * 3.2;
          ctx.beginPath();
          ctx.arc(4, 8, r, -Math.PI * 0.32, Math.PI * 0.32);
          ctx.stroke();
        }
      }
    }
  }

  HoverHandler {
    id: hoverHandler
    cursorShape: Qt.PointingHandCursor
  }

  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: function (event) {
      var step = Settings.data.audio.step;
      root._setVolume(root.volume + (event.angleDelta.y > 0 ? step : -step));
    }
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: menu.toggle()
  }

  TapHandler {
    acceptedButtons: Qt.RightButton
    onTapped: if (root.sink && root.sink.audio)
      root.sink.audio.muted = !root.sink.audio.muted
  }
}
