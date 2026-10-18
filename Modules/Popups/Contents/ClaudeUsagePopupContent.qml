import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Popups

// Claude Code plan limits and today's usage from ClaudeUsageService.
ColumnLayout {
  id: root

  spacing: Tokens.spaceLg

  // Bound to the owning SlideCard's `shown` from PopupHost; fetches fresh numbers on open.
  property bool active: false
  onActiveChanged: if (root.active)
    ClaudeUsageService.refresh()

  readonly property var record: ClaudeUsageService.record
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

  PopupHeader {
    title: "CLAUDE CODE"
    meta: root.tierLabel
  }

  NText {
    visible: root.usageStatusText !== ""
    text: root.usageStatusText
    color: Colors.error
    size: NText.Size.Caption
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
        NText {
          text: modelData.label || ""
          color: Colors.surfaceText
          size: NText.Size.BodySm
          Layout.fillWidth: true
        }
        NText {
          text: Math.round((modelData.percent || 0) * 100) + "%"
          color: (modelData.percent || 0) > 0.85 ? Colors.error : Colors.surfaceText
          size: NText.Size.BodySm
        }
      }

      SegMeter {
        Layout.fillWidth: true
        cellCount: Tokens.meterTelemetryCells
        cellHeight: Tokens.meterTelemetryCellHeight
        value: Math.min(100, (modelData.percent || 0) * 100)
        interactive: false
        filledColor: (modelData.percent || 0) > 0.85 ? Colors.error : Colors.primary
        emptyColor: Colors.surfaceContainerHigh
      }

      NText {
        text: root.formatResetsAt(modelData.resetsAt)
        color: Colors.labelText
        size: NText.Size.Caption
      }
    }
  }

  Rectangle {
    Layout.fillWidth: true
    height: Tokens.borderDivider
    color: Colors.surfaceContainerHigh
  }

  RowLayout {
    Layout.fillWidth: true
    NText {
      tracking: true
      text: "TODAY"
      color: Colors.labelText
      size: NText.Size.LabelXs
      Layout.fillWidth: true
    }
    NText {
      text: root.todayPrompts + " prompts · " + root.formatTokens(root.todayTotalTokens) + " tokens"
      color: Colors.surfaceText
      size: NText.Size.Caption
    }
  }
}
