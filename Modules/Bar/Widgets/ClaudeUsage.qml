import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras

// Compact session-usage readout on the bar; full detail (session + weekly,
// reset times, today's tokens) lives in the ClaudeUsageMenuWindow popup.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  readonly property string _binDir: Quickshell.env("HOME") + "/.config/quickshell/crux/bin/"
  property var record: ({})
  readonly property var limits: record.limits || []
  readonly property var sessionLimit: {
    for (var i = 0; i < limits.length; i++) {
      if (limits[i] && limits[i].label === "Session (5-hour)")
        return limits[i];
    }
    return null;
  }
  readonly property real sessionPercent: sessionLimit ? sessionLimit.percent : -1
  readonly property var weeklyLimit: {
    for (var i = 0; i < limits.length; i++) {
      if (limits[i] && limits[i].label === "Weekly (7-day)")
        return limits[i];
    }
    return null;
  }
  readonly property real weeklyPercent: weeklyLimit ? weeklyLimit.percent : -1

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
    interval: 60000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: if (!fetchProc.running)
      fetchProc.running = true
  }

  implicitWidth: icon.implicitWidth + 16
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  FontLoader {
    id: tablerIconFont
    source: Quickshell.shellDir + "/Assets/Fonts/noctalia-tabler-icons.ttf"
  }

  ClaudeUsageMenuWindow {
    id: menu
    targetScreen: root.screen
  }

  Rectangle {
    anchors.fill: parent
    radius: 2
    color: mouseArea.containsMouse ? "#45475a" : "transparent"

    Text {
      id: icon
      anchors.centerIn: parent
        text: "" // "robot" glyph — same icon noctalia uses for this widget
        font.family: tablerIconFont.name
        font.pixelSize: 20
        color: root.sessionPercent > 0.85 ? "#f38ba8" : "#cdd6f4"
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: menu.toggle()

    ToolTip {
      visible: mouseArea.containsMouse
      delay: 400
      font.family: Settings.data.ui.fontFamily
      text: {
        var parts = [];
        if (root.sessionPercent >= 0)
          parts.push("Session: " + Math.round(root.sessionPercent * 100) + "%");
        if (root.weeklyPercent >= 0)
          parts.push("Weekly: " + Math.round(root.weeklyPercent * 100) + "%");
        return parts.length > 0 ? parts.join("\n") : "Claude usage";
      }
    }
  }
}
