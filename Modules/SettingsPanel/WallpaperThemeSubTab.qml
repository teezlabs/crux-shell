import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Widgets
import qs.Services

// Matugen-driven theme generation, plus the per-app config templates it
// regenerates on every wallpaper change.
NScrollView {
  id: root
  contentHeight: col.implicitHeight


  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

    SettingsSection {
      title: "Theme generation"
      description: "Whenever a wallpaper below is picked, derive the whole color scheme from it via matugen — the same colors the Appearance tab's manual pickers edit."

      SettingRow {
        label: "Auto-theme"
        NToggle {
          checked: Settings.data.wallpaper.autoTheme
          onToggled: checked => Settings.data.wallpaper.autoTheme = checked
        }
        NText {
          text: "Regenerate colors on every pick"
          color: Colors.labelText
          size: NText.Size.Caption
        }
      }

      // Material 3 scheme type, rendered as chips (no dropdown control yet)
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        NText {
          tracking: true
          text: "SCHEME"
          color: Colors.labelText
          size: NText.Size.LabelXs
        }

        Flow {
          Layout.fillWidth: true
          spacing: 4

          Repeater {
            model: [
              {
                "mode": "scheme-content",
                "label": "Content"
              },
              {
                "mode": "scheme-expressive",
                "label": "Expressive"
              },
              {
                "mode": "scheme-fidelity",
                "label": "Fidelity"
              },
              {
                "mode": "scheme-fruit-salad",
                "label": "Fruit salad"
              },
              {
                "mode": "scheme-monochrome",
                "label": "Monochrome"
              },
              {
                "mode": "scheme-neutral",
                "label": "Neutral"
              },
              {
                "mode": "scheme-rainbow",
                "label": "Rainbow"
              },
              {
                "mode": "scheme-tonal-spot",
                "label": "Tonal spot"
              },
              {
                "mode": "scheme-vibrant",
                "label": "Vibrant"
              }
            ]

            delegate: Item {
              id: schemePill
              required property var modelData
              readonly property bool selected: Settings.data.wallpaper.matugenScheme === modelData.mode
              width: schemeLabel.implicitWidth + 20
              height: 26

              Chamfer {
                anchors.fill: parent
                chamferSize: Tokens.chamferIcon
                cutTopRight: true
                cutBottomLeft: true
                fillColor: schemePill.selected ? Colors.primary : Colors.surfaceContainer
              }

              NText {
                tracking: true
                id: schemeLabel
                anchors.centerIn: parent
                text: schemePill.modelData.label
                color: schemePill.selected ? Colors.primaryText : Colors.surfaceText
                size: NText.Size.LabelXs
              }

              HoverHandler {
                cursorShape: Qt.PointingHandCursor
              }
              TapHandler {
                onTapped: {
                  Settings.data.wallpaper.matugenScheme = schemePill.modelData.mode;
                  if (Settings.data.wallpaper.path !== "")
                    Matugen.generateFrom(Settings.data.wallpaper.path);
                }
              }
            }
          }
        }
      }

      RowLayout {
        spacing: 10

        NButton {
          enabled: Settings.data.wallpaper.path !== "" && !Matugen.running
          text: Matugen.running ? "Generating…" : "Regenerate colors now"
          onClicked: Matugen.generateFrom(Settings.data.wallpaper.path)
        }

        NButton {
          enabled: Settings.data.wallpaper.path !== "" && !Matugen.running
          text: "Cycle color (" + Settings.data.wallpaper.matugenColorIndex + "/4)"
          onClicked: Matugen.cycleColorIndex()
        }

        NText {
          visible: Matugen.lastError !== ""
          text: Matugen.lastError
          color: Colors.error
          size: NText.Size.Caption
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
        }
      }
    }

    SettingsSection {
      title: "System templates"
      description: "Also retheme these apps on every regenerate. Each writes a real config file; off means untouched, not reverted."

      Flow {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
          model: [
            {
              "key": "hyprland",
              "label": "Hyprland"
            },
            {
              "key": "kitty",
              "label": "Kitty"
            },
            {
              "key": "gtk",
              "label": "GTK"
            },
            {
              "key": "qt",
              "label": "Qt"
            },
            {
              "key": "yazi",
              "label": "Yazi"
            },
            {
              "key": "discord",
              "label": "Discord"
            },
            {
              "key": "pywalfox",
              "label": "Pywalfox"
            },
            {
              "key": "btop",
              "label": "btop"
            },
            {
              "key": "starship",
              "label": "Starship"
            },
            {
              "key": "sddmGreeter",
              "label": "SDDM greeter"
            },
            {
              "key": "gsettings",
              "label": "gsettings (dark mode)"
            }
          ]

          delegate: Item {
            id: tplPill
            required property var modelData
            readonly property bool selected: Settings.data.wallpaper.templates[modelData.key]
            width: tplLabel.implicitWidth + 20
            height: 26

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: tplPill.selected ? Colors.primary : Colors.surfaceContainer
            }

            NText {
              tracking: true
              id: tplLabel
              anchors.centerIn: parent
              text: tplPill.modelData.label
              color: tplPill.selected ? Colors.primaryText : Colors.surfaceText
              size: NText.Size.LabelXs
            }

            HoverHandler {
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: {
                Settings.data.wallpaper.templates[tplPill.modelData.key] = !tplPill.selected;
                if (Settings.data.wallpaper.path !== "")
                  Matugen.generateFrom(Settings.data.wallpaper.path);
              }
            }
          }
        }
      }
    }
  }
}
