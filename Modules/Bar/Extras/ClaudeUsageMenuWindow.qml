import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Modules.Bar.Extras

// Claude usage popup. Data from crux-agent-usage-claude.
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
  readonly property real _barOffset: Settings.data.bar.thickness + Settings.data.bar.floatMargin * 2 + 20

  // Bar-icon trigger position, mapped into this popup's space; -1 = not set (IPC open). See SoundMenuWindow.qml.
  property point triggerPos: Qt.point(-1, -1)
  readonly property bool _hasTrigger: triggerPos.x >= 0
  readonly property real _triggerX: triggerPos.x + Settings.data.bar.floatMargin
  readonly property real _triggerY: triggerPos.y + Settings.data.bar.floatMargin

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
    command: [root._binDir + "crux-agent-usage-claude", "--limits-only"]
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

  Item {
    id: card
    // Cross-axis position (along the bar's own length): lines up with the
    // triggering icon when known, clamped on-screen; falls back to the old
    // fixed near-corner inset otherwise. Main-axis position (the gap
    // between the bar and the popup) always uses _barOffset, unchanged.
    readonly property real _crossFallback: 12
    readonly property real _crossPos: {
      if (root._barLeft || root._barRight)
        return root._hasTrigger ? Math.max(8, Math.min(root._triggerY, root.height - card.height - 8)) : _crossFallback;
      return root._hasTrigger ? Math.max(8, Math.min(root._triggerX, root.width - card.width - 8)) : root.width - card.width - _crossFallback;
    }

    x: root._barLeft ? root._barOffset : (root._barRight ? root.width - card.width - root._barOffset : card._crossPos)
    y: root._barBottom ? root.height - card.height - root._barOffset : (root._barLeft || root._barRight ? card._crossPos : root._barOffset)
    width: 300
    height: Math.min(400, column.implicitHeight + 24)

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutTopRight: true
      cutBottomLeft: true
      fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
      strokeColor: Color.outline
      strokeWidth: Tokens.borderPanel
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      id: column
      anchors.fill: parent
      anchors.margins: 14
      spacing: 12

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "CLAUDE CODE"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.weight: Font.DemiBold
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          Layout.fillWidth: true
        }

        Text {
          visible: root.tierLabel !== ""
          text: root.tierLabel
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.captionSize
        }
      }

      Text {
        visible: root.usageStatusText !== ""
        text: root.usageStatusText
        color: Color.error
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.captionSize
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }

      Repeater {
        model: root.limits

        delegate: ColumnLayout {
          required property var modelData
          Layout.fillWidth: true
          spacing: 4

          RowLayout {
            Layout.fillWidth: true
            Text {
              text: modelData.label || ""
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
              Layout.fillWidth: true
            }
            Text {
              text: Math.round((modelData.percent || 0) * 100) + "%"
              color: (modelData.percent || 0) > 0.85 ? Color.error : Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
            }
          }

          SegMeter {
            Layout.fillWidth: true
            cellCount: Tokens.meterTelemetryCells
            cellHeight: Tokens.meterTelemetryCellHeight
            value: Math.min(100, (modelData.percent || 0) * 100)
            interactive: false
            filledColor: (modelData.percent || 0) > 0.85 ? Color.error : Color.primary
            emptyColor: Color.surfaceContainerHigh
          }

          Text {
            text: root.formatResetsAt(modelData.resetsAt)
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.captionSize
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: Tokens.borderDivider
        color: Color.surfaceContainerHigh
      }

      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "TODAY"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          Layout.fillWidth: true
        }
        Text {
          text: root.todayPrompts + " prompts · " + root.formatTokens(root.todayTotalTokens) + " tokens"
          color: Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.captionSize
        }
      }
    }
  }
}
