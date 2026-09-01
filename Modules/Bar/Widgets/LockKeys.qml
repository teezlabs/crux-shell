import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras

// Caps/Num/Scroll lock indicator. `hyprctl devices -j` reports capsLock and
// numLock per keyboard directly (same device-selection rule as
// KeyboardLayout.qml, sharing Settings.data.keyboard.deviceName). Scroll
// lock isn't in Hyprland's device JSON at all, and this box has no
// /sys/class/leds/*::scrolllock LED to fall back to either (checked
// directly — no lock LEDs exist in sysfs on this hardware), so its
// indicator always reads as "unknown" (dim, not lit) rather than lying
// about the state; the toggle to hide it entirely still works.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false

  property bool capsLockOn: false
  property bool numLockOn: false

  readonly property bool showCaps: Settings.data.lockKeys.showCapsLock
  readonly property bool showNum: Settings.data.lockKeys.showNumLock
  readonly property bool showScroll: Settings.data.lockKeys.showScrollLock
  readonly property bool hideWhenOff: Settings.data.lockKeys.hideWhenOff

  readonly property bool _anyVisible: (showCaps && (!hideWhenOff || capsLockOn)) || (showNum && (!hideWhenOff || numLockOn)) || (showScroll && !hideWhenOff)

  visible: _anyVisible
  implicitWidth: visible ? module.implicitWidth : 0
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  Process {
    id: devicesProc
    command: ["hyprctl", "-j", "devices"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(text);
          var keyboards = data.keyboards || [];
          var chosen = null;
          var wanted = Settings.data.keyboard.deviceName;
          if (wanted) {
            for (var i = 0; i < keyboards.length; i++) {
              if (keyboards[i].name === wanted) {
                chosen = keyboards[i];
                break;
              }
            }
          }
          if (!chosen) {
            for (var j = 0; j < keyboards.length; j++) {
              if (keyboards[j].main) {
                chosen = keyboards[j];
                break;
              }
            }
          }
          if (!chosen && keyboards.length > 0)
            chosen = keyboards[0];

          if (chosen) {
            root.capsLockOn = !!chosen.capsLock;
            root.numLockOn = !!chosen.numLock;
          }
        } catch (e) {
          // hyprctl not available / malformed JSON — leave last-known state.
        }
      }
    }
  }

  Timer {
    interval: 500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!devicesProc.running)
      devicesProc.running = true
  }

  BarModule {
    id: module
    vertical: root.vertical
    topPadding: 8
    bottomPadding: 8

    Row {
      visible: !root.vertical
      spacing: 6

      Text {
        visible: root.showCaps && (!root.hideWhenOff || root.capsLockOn)
        text: "C"
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelSize
        font.weight: Font.DemiBold
        color: root.capsLockOn ? Color.primary : Color.alpha(Color.surfaceTextMuted, 0.35)
      }
      Text {
        visible: root.showNum && (!root.hideWhenOff || root.numLockOn)
        text: "N"
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelSize
        font.weight: Font.DemiBold
        color: root.numLockOn ? Color.primary : Color.alpha(Color.surfaceTextMuted, 0.35)
      }
      Text {
        visible: root.showScroll && !root.hideWhenOff
        text: "S"
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelSize
        font.weight: Font.DemiBold
        color: Color.alpha(Color.surfaceTextMuted, 0.2)
      }
    }

    Column {
      visible: root.vertical
      spacing: 2

      Text {
        visible: root.showCaps && (!root.hideWhenOff || root.capsLockOn)
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: "C"
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.weight: Font.DemiBold
        color: root.capsLockOn ? Color.primary : Color.alpha(Color.surfaceTextMuted, 0.35)
      }
      Text {
        visible: root.showNum && (!root.hideWhenOff || root.numLockOn)
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: "N"
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.weight: Font.DemiBold
        color: root.numLockOn ? Color.primary : Color.alpha(Color.surfaceTextMuted, 0.35)
      }
      Text {
        visible: root.showScroll && !root.hideWhenOff
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: "S"
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.weight: Font.DemiBold
        color: Color.alpha(Color.surfaceTextMuted, 0.2)
      }
    }
  }

  HoverHandler {
    cursorShape: Qt.PointingHandCursor
    onHoveredChanged: {
      if (hovered) {
        var parts = ["Caps Lock: " + (root.capsLockOn ? "on" : "off"), "Num Lock: " + (root.numLockOn ? "on" : "off")];
        if (root.showScroll)
          parts.push("Scroll Lock: unavailable on this system");
        TooltipService.show(root, parts.join("\n"));
      } else {
        TooltipService.hide();
      }
    }
  }
}
