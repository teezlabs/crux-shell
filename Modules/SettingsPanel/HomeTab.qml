import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Landing page: what crux is running, the live palette, the most-used switches and shortcuts into the other tabs.
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  // Asks the window to open another tab (and optionally one of its subtabs).
  signal navigate(string tab, string subTab)

  readonly property string repoUrl: "https://github.com/teezlabs/crux-shell"
  property string commit: "…"
  property string version: ""

  readonly property string themeSource: {
    const preset = Settings.data.theme.colorScheme;
    const mode = Settings.data.theme.darkMode ? "dark" : "light";
    if (preset !== "")
      return preset + " preset, " + mode;
    return "From your wallpaper (" + Settings.data.wallpaper.matugenScheme.replace("scheme-", "") + "), " + mode;
  }

  Process {
    id: commitProc
    command: ["git", "-C", Quickshell.shellDir, "log", "-1", "--format=%h · %cd", "--date=short"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.commit = text.trim() || "unknown"
    }
  }

  Process {
    id: versionProc
    command: ["git", "-C", Quickshell.shellDir, "describe", "--tags", "--abbrev=0"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.version = text.trim()
    }
  }

  Component.onCompleted: {
    commitProc.running = true;
    versionProc.running = true;
  }

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

    RowLayout {
      Layout.fillWidth: true
      Layout.topMargin: Tokens.spaceSm
      spacing: Tokens.spaceXl

      ArchLogo {
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
      }

      ColumnLayout {
        spacing: Tokens.spaceXs

        NText {
          text: "crux"
          size: NText.Size.Title
          color: Colors.surfaceText
        }
        NText {
          tracking: true
          text: "SHARP BY DESIGN · " + (root.version !== "" ? root.version.toUpperCase() + " · " : "") + root.commit.toUpperCase()
          size: NText.Size.LabelXs
          color: Colors.labelText
        }
      }
    }

    SettingsSection {
      title: "Theme"
      description: root.themeSource

      RowLayout {
        spacing: Tokens.spaceMd

        Repeater {
          model: [
            {
              "label": "Primary",
              "color": Colors.primary
            },
            {
              "label": "Container",
              "color": Colors.primaryContainer
            },
            {
              "label": "Tertiary",
              "color": Colors.tertiary
            },
            {
              "label": "Surface",
              "color": Colors.surfaceContainerHigh
            },
            {
              "label": "Error",
              "color": Colors.error
            }
          ]

          delegate: ColumnLayout {
            required property var modelData
            spacing: Tokens.spaceSm

            Chamfer {
              Layout.preferredWidth: 56
              Layout.preferredHeight: 32
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: modelData.color
              strokeColor: Colors.outline
              strokeWidth: Tokens.borderModule
            }
            NText {
              tracking: true
              text: modelData.label.toUpperCase()
              size: NText.Size.LabelXs
              color: Colors.labelText
            }
          }
        }

        Item {
          Layout.fillWidth: true
        }

        NButton {
          text: "Wallpaper"
          onClicked: root.navigate("wallpaper", "library")
        }
        NButton {
          text: "Colors"
          onClicked: root.navigate("appearance", "colors")
        }
      }
    }

    SettingsSection {
      title: "Quick settings"
      description: "The switches you reach for most."

      SettingRow {
        label: "Dark mode"
        NToggle {
          checked: Matugen.darkMode
          onToggled: checked => Matugen.setDarkMode(checked)
        }
      }

      SettingRow {
        label: "Do not disturb"
        NToggle {
          checked: Settings.data.notifications.doNotDisturb
          onToggled: checked => Settings.data.notifications.doNotDisturb = checked
        }
      }

      SettingRow {
        label: "Floating bar"
        NToggle {
          checked: Settings.data.bar.floating
          onToggled: checked => Settings.data.bar.floating = checked
        }
      }
    }

    SettingsSection {
      title: "Jump to"
      description: "Shortcuts into the settings people change most."

      GridLayout {
        Layout.fillWidth: true
        columns: 3
        rowSpacing: Tokens.spaceMd
        columnSpacing: Tokens.spaceMd

        Repeater {
          model: [
            {
              "label": "Bar layout",
              "tab": "bar",
              "subTab": "layout"
            },
            {
              "label": "Bar widgets",
              "tab": "bar",
              "subTab": "widgets"
            },
            {
              "label": "Fonts and scale",
              "tab": "appearance",
              "subTab": "general"
            },
            {
              "label": "Notifications",
              "tab": "notifications",
              "subTab": "general"
            },
            {
              "label": "Lock screen",
              "tab": "lockScreen",
              "subTab": "appearance"
            },
            {
              "label": "Power and idle",
              "tab": "idle",
              "subTab": "behavior"
            },
            {
              "label": "Keybinds",
              "tab": "general",
              "subTab": "keybinds"
            },
            {
              "label": "Launcher",
              "tab": "launcher",
              "subTab": ""
            },
            {
              "label": "Plugins",
              "tab": "plugins",
              "subTab": "installed"
            }
          ]

          delegate: NButton {
            required property var modelData
            // Equal preferred widths so the three columns split the row evenly.
            Layout.preferredWidth: 1
            Layout.fillWidth: true
            text: modelData.label
            onClicked: root.navigate(modelData.tab, modelData.subTab)
          }
        }
      }
    }

    SettingsSection {
      title: "crux"
      description: "Restart reloads every widget and settings page, e.g. after editing a .qml file by hand."

      RowLayout {
        spacing: Tokens.spaceMd

        NButton {
          text: "Restart crux"
          variant: "accent"
          onClicked: Quickshell.execDetached(["bash", "-c", "pkill -f 'qs -c crux'; sleep 0.5; nohup qs -c crux --log-rules qt.qpa.wayland.textinput.warning=false >/dev/null 2>&1 & disown"])
        }
        NButton {
          text: "GitHub"
          onClicked: Qt.openUrlExternally(root.repoUrl)
        }
        NButton {
          text: "Report an issue"
          onClicked: Qt.openUrlExternally(root.repoUrl + "/issues/new")
        }
      }
    }
  }
}
