import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// Volume control: click opens the volume popup, scroll adjusts, right-click toggles mute.
// Styled as "LABEL value" (StatText) per spec §3's "status is text, not glyphs".
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property bool invertChamfer: false

  readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
  readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
  readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }

  function _setVolume(v) {
    if (!root.sink || !root.sink.audio)
      return;
    var maxVolume = Settings.data.audio.volumeOverdrive ? 1.5 : 1;
    root.sink.audio.volume = Math.max(0, Math.min(maxVolume, v));
    if (root.sink.audio.muted && v > 0)
      root.sink.audio.muted = false;
  }

  implicitWidth: module.implicitWidth
  implicitHeight: module.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarModule {
    id: module
    vertical: root.vertical
    invertChamfer: root.invertChamfer
    topPadding: 8
    bottomPadding: 8

    Row {
      visible: !root.vertical
      spacing: 10

      StatText {
        label: "VOL"
        value: root.muted ? "—" : String(Math.round(root.volume * 100))
        valueColor: root.muted ? Color.error : Color.surfaceText
      }
    }

    Column {
      visible: root.vertical
      spacing: 8

      Column {
        width: 24
        NText {
          tracking: true
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: root.muted ? "—" : String(Math.round(root.volume * 100))
          color: root.muted ? Color.error : Color.surfaceText
          size: NText.Size.LabelXs
        }
        NText {
          tracking: true
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: "VOL"
          color: Color.labelText
          font.pixelSize: Tokens.labelXsSize - 1
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
      }
    }
  }

  HoverHandler {
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: {
      var pos = root.mapToItem(null, 0, 0);
      Popups.openAt("sound", root.screen, pos.x, pos.y);
    }
  }
  TapHandler {
    acceptedButtons: Qt.RightButton
    onTapped: if (root.sink && root.sink.audio)
      root.sink.audio.muted = !root.sink.audio.muted
  }

  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: function (event) {
      var step = Settings.data.audio.step;
      root._setVolume(root.volume + (event.angleDelta.y > 0 ? step : -step));
    }
  }
}
