import QtQuick
import QtQuick.Effects
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

  // Anchor beside whichever edge the bar actually occupies instead of a
  // hardcoded screen corner — see the matching comment in
  // SoundMenuWindow.qml for the full reasoning.
  readonly property string _barPos: Settings.isLoaded ? Settings.getBarPositionForScreen(root.targetScreen ? root.targetScreen.name : "") : "top"
  readonly property bool _barLeft: root._barPos === "left"
  readonly property bool _barRight: root._barPos === "right"
  readonly property bool _barBottom: root._barPos === "bottom"
  readonly property real _barOffset: Settings.data.bar.thickness + Settings.data.bar.floatMargin * 2 + 8

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

  // Soft drop shadow behind the card, same treatment as the bar itself
  // (shell.qml) — depth against whatever's behind the popup.
  MultiEffect {
    anchors.fill: card
    source: card
    shadowEnabled: true
    shadowColor: Qt.rgba(0, 0, 0, 0.55)
    shadowBlur: 0.7
    shadowVerticalOffset: 3
    shadowHorizontalOffset: 0
  }

  Rectangle {
    id: card
    anchors.top: !root._barBottom ? parent.top : undefined
    anchors.bottom: root._barBottom ? parent.bottom : undefined
    anchors.left: root._barLeft ? parent.left : undefined
    anchors.right: !root._barLeft ? parent.right : undefined
    anchors.topMargin: !root._barBottom ? (root._barLeft || root._barRight ? 12 : root._barOffset) : 0
    anchors.bottomMargin: root._barBottom ? root._barOffset : 0
    anchors.leftMargin: root._barLeft ? root._barOffset : 0
    anchors.rightMargin: !root._barLeft ? (root._barRight ? root._barOffset : 12) : 0
    width: 300
    height: Math.min(400, column.implicitHeight + 24)
    radius: Style.radiusXXS
    color: Color.mSurface
    border.color: Color.mOutline
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
          color: Color.mOnSurface
          font.pixelSize: 14
          font.bold: true
          Layout.fillWidth: true
        }

        Text {
          font.family: Settings.data.ui.fontFamily
          visible: root.tierLabel !== ""
          text: root.tierLabel
          color: Color.mOnSurfaceVariant
          font.pixelSize: 11
        }
      }

      Text {
        font.family: Settings.data.ui.fontFamily
        visible: root.usageStatusText !== ""
        text: root.usageStatusText
        color: Color.mError
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
              color: Color.mOnSurface
              font.pixelSize: 12
              Layout.fillWidth: true
            }
            Text {
              font.family: Settings.data.ui.fontFamily
              text: Math.round((modelData.percent || 0) * 100) + "%"
              color: Color.mOnSurface
              font.pixelSize: 12
            }
          }

          Rectangle {
            Layout.fillWidth: true
            height: 6
            radius: 1
            color: Color.mSurfaceVariant

            Rectangle {
              width: parent.width * Math.min(1, modelData.percent || 0)
              height: parent.height
              radius: 1
              color: (modelData.percent || 0) > 0.85 ? Color.mError : Color.mPrimary
            }
          }

          Text {
            font.family: Settings.data.ui.fontFamily
            text: root.formatResetsAt(modelData.resetsAt)
            color: Color.mOnSurfaceVariant
            font.pixelSize: 10
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Color.mOutline
      }

      RowLayout {
        Layout.fillWidth: true
        Text {
          font.family: Settings.data.ui.fontFamily
          text: "Today"
          color: Color.mOnSurfaceVariant
          font.pixelSize: 11
          Layout.fillWidth: true
        }
        Text {
          font.family: Settings.data.ui.fontFamily
          text: root.todayPrompts + " prompts · " + root.formatTokens(root.todayTotalTokens) + " tokens"
          color: Color.mOnSurface
          font.pixelSize: 11
        }
      }
    }
  }
}
