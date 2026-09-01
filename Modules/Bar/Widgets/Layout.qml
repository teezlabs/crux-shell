import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras

// v2 spec §6.1 Layout module: "TILE · MASTER", label grey. Both halves are
// real Hyprland state, not decoration: left is the focused window's
// tiled/floating state (hyprctl activewindow), right is the active layout
// engine (hyprctl getoption general:layout — dwindle/master/whatever plugin
// is loaded, e.g. this box's own "scrolling" from the scrolloverview plugin
// per the crux skill's Hyprland config notes).
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false

  property bool floating: false
  property string layoutName: "…"

  function refreshWindowState() {
    windowProc.running = true;
  }

  function refreshLayoutName() {
    layoutProc.running = true;
  }

  Process {
    id: windowProc
    command: ["hyprctl", "activewindow", "-j"]
    stdout: StdioCollector {
      id: windowCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      try {
        var data = JSON.parse(windowCollector.text);
        root.floating = !!data.floating;
      } catch (e) {}
    }
  }

  Process {
    id: layoutProc
    command: ["hyprctl", "getoption", "general:layout", "-j"]
    stdout: StdioCollector {
      id: layoutCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      try {
        var data = JSON.parse(layoutCollector.text);
        root.layoutName = (data.str || "?").toUpperCase();
      } catch (e) {}
    }
  }

  Component.onCompleted: {
    refreshWindowState();
    refreshLayoutName();
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      root.refreshWindowState();
    }
  }

  implicitWidth: module.implicitWidth
  implicitHeight: module.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarModule {
    id: module
    vertical: root.vertical

    Row {
      visible: !root.vertical
      spacing: 6

      Text {
        text: root.floating ? "FLOAT" : "TILE"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelSize
        font.letterSpacing: Tokens.labelSize * Tokens.labelTracking
      }
      Text {
        text: "·"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelSize
      }
      Text {
        text: root.layoutName
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelSize
        font.letterSpacing: Tokens.labelSize * Tokens.labelTracking
      }
    }

    Column {
      visible: root.vertical
      spacing: 2

      Text {
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: root.floating ? "FLT" : "TILE"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
      }
      Text {
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: root.layoutName
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
      }
    }
  }
}
