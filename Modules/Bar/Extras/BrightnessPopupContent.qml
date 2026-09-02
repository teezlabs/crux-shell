import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons

// Brightness popup content — self-contained backlight detection/set,
// duplicated from Brightness.qml's bar widget rather than shared, since
// content and widget now live in separate window trees (PopupHost is
// decoupled from the bar). Two independent brightnessctl probes running
// is a known, accepted tradeoff here, not an oversight — a real shared
// service would be the cleaner fix if this needs revisiting.
ColumnLayout {
  id: root

  spacing: 12

  property string backlightDevice: ""
  property real maxBrightness: 100
  property real brightness: 0 // 0..1
  property real queuedBrightness: NaN
  property bool available: false

  readonly property int percent: Math.round(root.brightness * 100)

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

  Component.onCompleted: detectProc.running = true

  Text {
    text: "BRIGHTNESS"
    color: Color.labelText
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.labelXsSize
    font.weight: Font.DemiBold
    font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: 10

    SegMeter {
      Layout.fillWidth: true
      cellCount: Tokens.meterControlCenterCells
      cellHeight: Tokens.meterControlCenterCellHeight
      value: root.percent
      interactive: true
      filledColor: Color.primary
      emptyColor: Color.surfaceContainerHigh
      onMoved: pct => root.setBrightness(pct / 100)
    }

    Text {
      text: root.percent + "%"
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.bodySmSize
      Layout.preferredWidth: 34
    }
  }

  Text {
    visible: !root.available
    text: "No internal backlight device detected."
    color: Color.labelText
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.captionSize
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }
}
