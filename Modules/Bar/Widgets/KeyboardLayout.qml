import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// Active keyboard layout, polled via `hyprctl devices -j` every 2s; click cycles via switchxkblayout.
// Settings.data.keyboard.deviceName lets the user pin a device — `devices -j` can list many fake "keyboards" (mice, power buttons, virtual devices) so auto-picking the first isn't reliable.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false

  property string currentLayout: "--"
  property string fullLayoutName: ""
  property string deviceName: ""

  function _extractCode(layoutString) {
    if (!layoutString)
      return "--";
    var str = layoutString.trim();
    // "English (US)" -> "US"; "German (deadkeys)" -> "DE" fallback below
    var m = str.match(/\(([a-zA-Z]{2,3})\)/);
    if (m)
      return m[1].toUpperCase();
    // Already a short xkb code like "us" or "us+intl"
    if (/^[a-zA-Z]{2,3}(\+.*)?$/.test(str))
      return str.split("+")[0].toUpperCase();
    // Fallback: first two letters of the first word
    var word = str.split(/[\s(]/)[0];
    return (word.substring(0, 2) || "--").toUpperCase();
  }

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
            root.deviceName = chosen.name || "";
            root.fullLayoutName = chosen.active_keymap || "";
            root.currentLayout = root._extractCode(chosen.active_keymap);
          }
        } catch (e) {
          // hyprctl not available / malformed JSON — leave last-known value.
        }
      }
    }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!devicesProc.running)
      devicesProc.running = true
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
        label: "KBD"
        value: root.currentLayout
        valueColor: Color.surfaceText
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
          text: root.currentLayout
          color: Color.surfaceText
          size: NText.Size.LabelXs
        }
        NText {
          tracking: true
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: "KBD"
          color: Color.labelText
          font.pixelSize: Tokens.labelXsSize - 1
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
      }
    }
  }

  HoverHandler {
    id: hoverHandler
    cursorShape: Qt.PointingHandCursor
    onHoveredChanged: {
      if (hovered) {
        TooltipService.show(root, root.fullLayoutName || "Keyboard layout");
      } else {
        TooltipService.hide();
      }
    }
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: {
      TooltipService.hideImmediately();
      if (root.deviceName)
        Quickshell.execDetached(["hyprctl", "switchxkblayout", root.deviceName, "next"]);
      // Layouts take effect immediately in Hyprland; poll right away
      // instead of waiting for the next 2s tick so the click feels responsive.
      devicesProc.running = true;
    }
  }
}
