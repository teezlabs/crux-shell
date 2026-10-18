import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Widgets
import qs.Modules.Bar.Extras

// Mirror of Sound.qml for the default source: click opens the mic popup, scroll adjusts, right-click mutes.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property bool invertChamfer: false

  readonly property var source: Pipewire.ready ? Pipewire.defaultAudioSource : null
  readonly property real volume: source && source.audio ? source.audio.volume : 0
  readonly property bool muted: source && source.audio ? source.audio.muted : false

  PwObjectTracker {
    objects: root.source ? [root.source] : []
  }

  function _setVolume(v) {
    if (!root.source || !root.source.audio)
      return;
    root.source.audio.volume = Math.max(0, Math.min(1, v));
    if (root.source.audio.muted && v > 0)
      root.source.audio.muted = false;
  }

  implicitWidth: module.implicitWidth
  implicitHeight: module.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarModule {
    id: module
    invertChamfer: root.invertChamfer
    vertical: root.vertical
    topPadding: 8
    bottomPadding: 8

    Row {
      visible: !root.vertical
      spacing: 10

      StatText {
        label: "MIC"
        value: root.muted ? "—" : String(Math.round(root.volume * 100))
        valueColor: root.muted ? Colors.error : Colors.surfaceText
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
          color: root.muted ? Colors.error : Colors.surfaceText
          size: NText.Size.LabelXs
        }
        NText {
          tracking: true
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: "MIC"
          color: Colors.labelText
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
      Popups.openFrom("microphone", root.screen, pos.x, pos.y, root.width, root.height);
    }
  }
  TapHandler {
    acceptedButtons: Qt.RightButton
    onTapped: if (root.source && root.source.audio)
      root.source.audio.muted = !root.source.audio.muted
  }

  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: function (event) {
      var step = Settings.data.audio.step;
      root._setVolume(root.volume + (event.angleDelta.y > 0 ? step : -step));
    }
  }
}
