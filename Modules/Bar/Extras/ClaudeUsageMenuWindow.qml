import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

// Claude usage popup. Data comes straight from Omarchy's
// omarchy-agent-usage-claude collector (copied verbatim from upstream —
// pure Python, stdlib-only, reads ~/.claude locally + Anthropic's OAuth
// usage endpoint with the CLI's own saved token). UI rebuilt on crux's own
// primitives instead of Omarchy's shared Ui kit / multi-agent panel.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property string _binDir: Quickshell.env("HOME") + "/.config/quickshell/crux/bin/"

  property var record: ({})
  readonly property var limits: record.limits || []
  readonly property string tierLabel: record.tierLabel || ""
  readonly property int todayPrompts: record.todayPrompts || 0
  readonly property real todayTotalTokens: record.todayTotalTokens || 0
  readonly property string usageStatusText: record.usageStatusText || ""

  function formatResetsAt(iso) {
    if (!iso)
      return "";
    var d = new Date(iso);
    if (isNaN(d.getTime()))
      return "";
    var diffMs = d - new Date();
    if (diffMs <= 0)
      return "resets soon";
    var hours = Math.floor(diffMs / 3600000);
    var days = Math.floor(hours / 24);
    if (days > 0)
      return "resets in " + days + "d " + (hours % 24) + "h";
    var mins = Math.floor((diffMs % 3600000) / 60000);
    return "resets in " + hours + "h " + mins + "m";
  }

  function formatTokens(n) {
    if (n >= 1000000)
      return (n / 1000000).toFixed(1) + "M";
    if (n >= 1000)
      return (n / 1000).toFixed(1) + "K";
    return String(Math.round(n));
  }

  Process {
    id: fetchProc
    command: [root._binDir + "omarchy-agent-usage-claude", "--limits-only"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          root.record = JSON.parse(text);
        } catch (e) {}
      }
    }
  }

  Timer {
    interval: 30000
    repeat: true
    running: root.visible
    triggeredOnStart: true
    onTriggered: if (!fetchProc.running)
      fetchProc.running = true
  }

  visible: false
  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-claude-usage-menu"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  function toggle() {
    visible = !visible;
    if (visible && !fetchProc.running)
      fetchProc.running = true;
  }

  IpcHandler {
    enabled: root.targetScreen === Quickshell.screens[0]
    target: "claudeUsage"
    function toggle() {
      root.toggle();
    }
    function open() {
      if (!root.visible)
        root.toggle();
    }
    function close() {
      root.visible = false;
    }
  }

  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.visible = false
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.visible = false
  }

  Rectangle {
    id: card
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: 40
    anchors.rightMargin: 12
    width: 300
    height: Math.min(400, column.implicitHeight + 24)
    radius: 2
    color: "#1e1e2e"
    border.color: "#45475a"
    border.width: 1

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      id: column
      anchors.fill: parent
      anchors.margins: 12
      spacing: 10

      RowLayout {
        Layout.fillWidth: true

        Text {
          font.family: Settings.data.ui.fontFamily
          text: "Claude Code"
          color: "#cdd6f4"
          font.pixelSize: 14
          font.bold: true
          Layout.fillWidth: true
        }

        Text {
          font.family: Settings.data.ui.fontFamily
          visible: root.tierLabel !== ""
          text: root.tierLabel
          color: "#6c7086"
          font.pixelSize: 11
        }
      }

      Text {
        font.family: Settings.data.ui.fontFamily
        visible: root.usageStatusText !== ""
        text: root.usageStatusText
        color: "#f9e2af"
        font.pixelSize: 11
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }

      Repeater {
        model: root.limits

        delegate: ColumnLayout {
          required property var modelData
          Layout.fillWidth: true
          spacing: 2

          RowLayout {
            Layout.fillWidth: true
            Text {
              font.family: Settings.data.ui.fontFamily
              text: modelData.label || ""
              color: "#cdd6f4"
              font.pixelSize: 12
              Layout.fillWidth: true
            }
            Text {
              font.family: Settings.data.ui.fontFamily
              text: Math.round((modelData.percent || 0) * 100) + "%"
              color: "#cdd6f4"
              font.pixelSize: 12
            }
          }

          Rectangle {
            Layout.fillWidth: true
            height: 6
            radius: 1
            color: "#313244"

            Rectangle {
              width: parent.width * Math.min(1, modelData.percent || 0)
              height: parent.height
              radius: 1
              color: (modelData.percent || 0) > 0.85 ? "#f38ba8" : "#89b4fa"
            }
          }

          Text {
            font.family: Settings.data.ui.fontFamily
            text: root.formatResetsAt(modelData.resetsAt)
            color: "#6c7086"
            font.pixelSize: 10
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: "#45475a"
      }

      RowLayout {
        Layout.fillWidth: true
        Text {
          font.family: Settings.data.ui.fontFamily
          text: "Today"
          color: "#6c7086"
          font.pixelSize: 11
          Layout.fillWidth: true
        }
        Text {
          font.family: Settings.data.ui.fontFamily
          text: root.todayPrompts + " prompts · " + root.formatTokens(root.todayTotalTokens) + " tokens"
          color: "#cdd6f4"
          font.pixelSize: 11
        }
      }
    }
  }
}
