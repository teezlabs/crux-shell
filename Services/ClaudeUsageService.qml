pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Claude Code plan limits from crux-agent-usage-claude, polled while a ClaudeUsage widget exists.
Singleton {
  id: root

  property var record: ({})
  readonly property var limits: record.limits || []
  readonly property var sessionLimit: limits.find(l => l && l.label === "Session (5-hour)") || null
  readonly property var weeklyLimit: limits.find(l => l && l.label === "Weekly (7-day)") || null

  property int watchers: 0

  function refresh(): void {
    if (!fetchProc.running)
      fetchProc.running = true;
  }

  readonly property Timer poll: Timer {
    interval: 60000
    repeat: true
    running: root.watchers > 0
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  readonly property Process fetchProc: Process {
    command: [Quickshell.shellDir + "/bin/crux-agent-usage-claude", "--limits-only"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          root.record = JSON.parse(text);
        } catch (e) {}
      }
    }
  }
}
