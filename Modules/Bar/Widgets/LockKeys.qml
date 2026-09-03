import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// Caps/Num/Scroll lock indicator. capsLock/numLock come from `hyprctl devices -j`; scroll lock has no
// source on this hardware (not in Hyprland's JSON, no sysfs LED either) so it always shows "unknown", not a bug.
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

      NText {
        visible: root.showCaps && (!root.hideWhenOff || root.capsLockOn)
        text: "C"
        size: NText.Size.Label
        font.weight: Font.DemiBold
        color: root.capsLockOn ? Color.primary : Color.alpha(Color.surfaceTextMuted, 0.35)
      }
      NText {
        visible: root.showNum && (!root.hideWhenOff || root.numLockOn)
        text: "N"
        size: NText.Size.Label
        font.weight: Font.DemiBold
        color: root.numLockOn ? Color.primary : Color.alpha(Color.surfaceTextMuted, 0.35)
      }
      NText {
        visible: root.showScroll && !root.hideWhenOff
        text: "S"
        size: NText.Size.Label
        font.weight: Font.DemiBold
        color: Color.alpha(Color.surfaceTextMuted, 0.2)
      }
    }

    Column {
      visible: root.vertical
      spacing: 2

      NText {
        visible: root.showCaps && (!root.hideWhenOff || root.capsLockOn)
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: "C"
        size: NText.Size.LabelXs
        font.weight: Font.DemiBold
        color: root.capsLockOn ? Color.primary : Color.alpha(Color.surfaceTextMuted, 0.35)
      }
      NText {
        visible: root.showNum && (!root.hideWhenOff || root.numLockOn)
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: "N"
        size: NText.Size.LabelXs
        font.weight: Font.DemiBold
        color: root.numLockOn ? Color.primary : Color.alpha(Color.surfaceTextMuted, 0.35)
      }
      NText {
        visible: root.showScroll && !root.hideWhenOff
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: "S"
        size: NText.Size.LabelXs
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
