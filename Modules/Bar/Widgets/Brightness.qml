import QtQuick
import Quickshell
import Quickshell.Io
import qs.Modules.Bar.Extras
import qs.Commons

// Internal-backlight brightness readout + scroll-to-adjust, via
// brightnessctl — the same tool noctalia's BrightnessService.qml shells out
// to for non-DDC/non-Apple displays. DDC (external monitor) and Apple
// Studio Display support from noctalia's service were deliberately not
// ported (real added complexity — per-monitor ddcutil detection/bus
// numbers — for hardware this box doesn't have); a laptop's own panel is
// the common case this covers. Device detection + get/set both run as
// one-shot `sh -c`/`brightnessctl` Process calls, same "no separate
// service singleton" spirit as Sound.qml's direct Pipewire access.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false

  property string backlightDevice: ""
  property real maxBrightness: 100
  property real brightness: 0 // 0..1
  property real queuedBrightness: NaN
  property bool available: false

  readonly property int percent: Math.round(root.brightness * 100)

  implicitWidth: root.available ? module.implicitWidth : 0
  implicitHeight: root.available ? module.implicitHeight : 0
  width: implicitWidth
  height: implicitHeight
  visible: root.available
  opacity: root.available ? 1.0 : 0.0

  BrightnessMenuWindow {
    id: menu
    targetScreen: root.screen
    controller: root
  }

  function _clamp(value) {
    var min = Settings.data.brightness.enforceMinimum ? 0.01 : 0;
    return Math.max(min, Math.min(1, value));
  }

  function setBrightness(value) {
    var clamped = root._clamp(value);
    root.brightness = clamped; // optimistic UI update
    root.queuedBrightness = clamped;
    setDebounce.restart();
  }

  function adjustBrightness(delta) {
    root.setBrightness(root.brightness + delta);
  }

  Timer {
    id: setDebounce
    interval: 60
    onTriggered: {
      if (isNaN(root.queuedBrightness) || root.backlightDevice === "")
        return;
      var rounded = Math.round(root.queuedBrightness * 100);
      var args = ["brightnessctl", "-d", root.backlightDevice, "s", rounded + "%"];
      if (Settings.data.brightness.enforceMinimum)
        args.push("-n");
      setProc.command = args;
      setProc.running = true;
      root.queuedBrightness = NaN;
    }
  }

  Process {
    id: setProc
    onExited: {
      if (!isNaN(root.queuedBrightness))
        setDebounce.restart();
    }
  }

  // Detect the first usable internal backlight device and its current
  // level in one shot: device basename, current, max — three lines.
  Process {
    id: detectProc
    command: ["sh", "-c", "for dev in /sys/class/backlight/*; do if [ -f \"$dev/brightness\" ] && [ -f \"$dev/max_brightness\" ]; then basename \"$dev\"; cat \"$dev/brightness\"; cat \"$dev/max_brightness\"; break; fi; done"]
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.trim().split("\n");
        if (lines.length < 3 || lines[0] === "") {
          root.available = false;
          return;
        }
        var current = parseInt(lines[1]);
        var max = parseInt(lines[2]);
        if (isNaN(current) || isNaN(max) || max <= 0) {
          root.available = false;
          return;
        }
        root.backlightDevice = lines[0];
        root.maxBrightness = max;
        root.brightness = current / max;
        root.available = true;
      }
    }
  }

  // Picks up external brightness changes (hardware keys handled outside
  // this shell, another brightnessctl caller, etc).
  FileView {
    id: brightnessWatcher
    path: root.backlightDevice !== "" ? "/sys/class/backlight/" + root.backlightDevice + "/brightness" : ""
    watchChanges: path !== ""
    onFileChanged: Qt.callLater(function () {
      detectProc.running = true;
    })
  }

  Component.onCompleted: detectProc.running = true

  BarModule {
    id: module
    vertical: root.vertical
    topPadding: 8
    bottomPadding: 8

    Row {
      visible: !root.vertical
      spacing: 10

      StatText {
        label: "BRI"
        value: root.percent + "%"
        valueColor: Color.surfaceText
      }
    }

    Column {
      visible: root.vertical
      spacing: 8

      Column {
        width: 24
        Text {
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: root.percent + "%"
          color: Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
        Text {
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: "BRI"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize - 1
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
      }
    }
  }

  HoverHandler {
    cursorShape: Qt.PointingHandCursor
    onHoveredChanged: {
      if (hovered)
        TooltipService.show(root, "Brightness " + root.percent + "%");
      else
        TooltipService.hide();
    }
  }

  TapHandler {
    onTapped: {
      TooltipService.hideImmediately();
      menu.triggerPos = root.mapToItem(null, 0, 0);
      menu.toggle();
    }
  }

  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: function (event) {
      var step = Settings.data.brightness.step / 100.0;
      root.adjustBrightness(event.angleDelta.y > 0 ? step : -step);
    }
  }

  onPercentChanged: if (TooltipService.anchorItem === root)
    TooltipService.text = "Brightness " + root.percent + "%"
}
