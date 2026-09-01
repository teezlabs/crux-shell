import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.SettingsPanel.Controls

// About tab: shell/path/commit info. Git metadata read live, not hardcoded.
Flickable {
  id: root
  clip: true
  contentWidth: width
  contentHeight: col.implicitHeight

  property string commitHash: "…"
  property string commitDate: "…"
  property string qsVersion: "…"

  Process {
    id: hashProc
    command: ["git", "-C", Quickshell.shellDir, "rev-parse", "--short", "HEAD"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.commitHash = text.trim() || "unknown"
    }
  }

  Process {
    id: dateProc
    command: ["git", "-C", Quickshell.shellDir, "log", "-1", "--format=%cd", "--date=short"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.commitDate = text.trim() || "unknown"
    }
  }

  Process {
    id: versionProc
    command: ["qs", "--version"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.qsVersion = text.trim() || "unknown"
    }
  }

  Component.onCompleted: {
    hashProc.running = true;
    dateProc.running = true;
    versionProc.running = true;
  }

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

  SettingsSection {
    title: "crux"
    description: "A personal QuickShell build for Hyprland."

    GridLayout {
      Layout.fillWidth: true
      columns: 2
      columnSpacing: 16
      rowSpacing: 8

      Text {
        Layout.alignment: Qt.AlignTop
        text: "Commit"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
      Text {
        Layout.fillWidth: true
        text: root.commitHash + " (" + root.commitDate + ")"
        color: Color.surfaceText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
        wrapMode: Text.WrapAnywhere
      }

      Text {
        Layout.alignment: Qt.AlignTop
        text: "Config dir"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
      Text {
        Layout.fillWidth: true
        text: Quickshell.shellDir
        color: Color.surfaceText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
        wrapMode: Text.WrapAnywhere
      }

      Text {
        Layout.alignment: Qt.AlignTop
        text: "Settings file"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
      Text {
        Layout.fillWidth: true
        text: Settings.settingsFile
        color: Color.surfaceText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
        wrapMode: Text.WrapAnywhere
      }

      Text {
        Layout.alignment: Qt.AlignTop
        text: "Quickshell"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
      Text {
        Layout.fillWidth: true
        text: root.qsVersion
        color: Color.surfaceText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
        wrapMode: Text.WrapAnywhere
      }
    }
  }
  }
}
