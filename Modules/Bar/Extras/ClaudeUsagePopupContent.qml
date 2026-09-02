import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons

// Claude usage popup content. Data from crux-agent-usage-claude. Hosted
// inside a SlideCard by PopupHost.qml — no window/positioning of its own.
ColumnLayout {
  id: root

  spacing: 12

  // Bound to the owning SlideCard's `open` from PopupHost — drives the
  // refresh timer and an immediate fetch on open, same as the old
  // toggle()-triggered fetch.
  property bool active: false
  onActiveChanged: if (root.active && !fetchProc.running)
    fetchProc.running = true

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
    running: root.active
    triggeredOnStart: true
    onTriggered: if (!fetchProc.running)
      fetchProc.running = true
  }

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
