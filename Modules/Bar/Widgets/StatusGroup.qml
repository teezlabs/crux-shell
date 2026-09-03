import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// Merged NET/VOL/BAT status module (spec §6.1), split by 1px dividers. Click opens Control Center.
// BAT segment only shows if a power_supply device is present — no fake 100% on battery-less desktops.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false

  readonly property var wifiDevice: {
    var devices = Networking.devices ? Networking.devices.values : [];
    for (var i = 0; i < devices.length; i++) {
      if (devices[i] && devices[i].type === DeviceType.Wifi)
        return devices[i];
    }
    return null;
  }
  readonly property bool wifiConnected: {
    var networks = wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : [];
    for (var i = 0; i < networks.length; i++)
      if (networks[i] && networks[i].connected)
        return true;
    return false;
  }
  readonly property string netLabel: !Networking.wifiEnabled ? "OFF" : (wifiConnected ? "WLAN" : "SRCH")

  readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
  readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
  readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

  PwObjectTracker {
    objects: root.sink ? [root.sink] : []
  }

  property bool hasBattery: false
  property int batteryPercent: 0

  Process {
    id: batProc
    command: ["sh", "-c", "cat /sys/class/power_supply/*/capacity 2>/dev/null | head -1"]
    stdout: StdioCollector {
      id: batCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      var text = batCollector.text.trim();
      root.hasBattery = text !== "";
      root.batteryPercent = parseInt(text) || 0;
    }
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: batProc.running = true
  }

  implicitWidth: module.implicitWidth
  implicitHeight: module.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarModule {
    id: module
    vertical: root.vertical
    topPadding: 8
    bottomPadding: 8

    Row {
      visible: !root.vertical
      spacing: 10

      StatText {
        label: "NET"
        value: root.netLabel
        valueColor: Networking.wifiEnabled ? Color.surfaceText : Color.disabledText
      }

      Rectangle {
        width: 1
        height: 12
        color: Color.surfaceContainerHigh
      }

      StatText {
        label: "VOL"
        value: root.muted ? "—" : String(Math.round(root.volume * 100))
        valueColor: root.muted ? Color.error : Color.surfaceText
      }

      Rectangle {
        visible: root.hasBattery
        width: 1
        height: 12
        color: Color.surfaceContainerHigh
      }

      StatText {
        visible: root.hasBattery
        label: "BAT"
        value: String(root.batteryPercent)
      }

      SegMeter {
        visible: root.hasBattery
        width: 26
        value: root.batteryPercent
        cellCount: Tokens.meterBarBatteryCells
        cellHeight: Tokens.meterBarBatteryCellHeight
      }
    }

    // Vertical bar: stacked value/label pairs instead of "LABEL value"; battery meter dropped, percentage alone carries it.
    Column {
      visible: root.vertical
      spacing: 8

      Column {
        width: 24
        NText {
          tracking: true
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: root.netLabel
          color: Networking.wifiEnabled ? Color.surfaceText : Color.disabledText
          size: NText.Size.LabelXs
        }
        NText {
          tracking: true
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: "NET"
          color: Color.labelText
          font.pixelSize: Tokens.labelXsSize - 1
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
      }

      Rectangle {
        width: 24
        height: 1
        color: Color.surfaceContainerHigh
      }

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

      Rectangle {
        visible: root.hasBattery
        width: 24
        height: 1
        color: Color.surfaceContainerHigh
      }

      Column {
        visible: root.hasBattery
        width: 24
        NText {
          tracking: true
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: String(root.batteryPercent)
          color: Color.surfaceText
          size: NText.Size.LabelXs
        }
        NText {
          tracking: true
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: "BAT"
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
    onTapped: {
      var pos = root.mapToItem(null, 0, 0);
      Popups.openAt("controlCenter", root.screen, pos.x, pos.y);
    }
  }

  // Scroll-to-adjust volume — this module (not the standalone Sound.qml
  // widget, which isn't in the default bar layout) is what's actually on
  // the bar, so this is where users expect to be able to scroll to change
  // volume. Same step-size convention Sound.qml/VolumeOsd's IPC already use.
  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: function (event) {
      if (!root.sink || !root.sink.audio)
        return;
      var step = Settings.data.audio.step;
      var next = Math.max(0, Math.min(1, root.volume + (event.angleDelta.y > 0 ? step : -step)));
      root.sink.audio.volume = next;
      if (root.sink.audio.muted && next > 0)
        root.sink.audio.muted = false;
    }
  }
}
