import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Widgets
import qs.Services

// Wallpaper library: the picker grid, the auto-cycle automation that drives
// it, and the Wallhaven API key the browser needs.
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  property var files: []

  function rescan() {
    listProc.command = ["find", Settings.data.wallpaper.directory, "-maxdepth", "1", "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")"];
    listProc.running = true;
  }

  Component.onCompleted: rescan()

  Process {
    id: listProc
    stdout: StdioCollector {
      id: listCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      var lines = listCollector.text.split("\n").filter(l => l.length > 0);
      lines.sort();
      root.files = lines;
    }
  }

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

    SettingsSection {
      title: "Wallpapers"
      description: "Current: " + (Settings.data.wallpaper.path || "(none set)")

      ColumnLayout {
        id: wallpapersCol
        Layout.fillWidth: true
        spacing: 10

        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          NTextInput {
            id: dirInput
            Layout.fillWidth: true
            height: 28
            text: Settings.data.wallpaper.directory
            onEditingFinished: {
            Settings.data.wallpaper.directory = text;
            root.rescan();
            }
          }

          NText {
            text: root.files.length + " found"
            color: Colors.labelText
            size: NText.Size.Caption
          }
        }

        // Column count comes from the width available, not a fixed 5. Five
        // 130px cells plus their gaps need 682px and the content pane is
        // about 660, so the last column used to render past the card's
        // right edge. Driven off the enclosing column's width rather than
        // the grid's own, which would be a binding loop.
        GridLayout {
          id: thumbGrid
          Layout.fillWidth: true
          rowSpacing: 8
          columnSpacing: 8

          readonly property int minCell: 130
          readonly property real available: wallpapersCol.width
          columns: Math.max(1, Math.floor((available + columnSpacing) / (minCell + columnSpacing)))
          // Cells share the row evenly rather than leaving a ragged gap.
          readonly property real cellWidth: columns > 0 ? (available - columnSpacing * (columns - 1)) / columns : minCell
          readonly property real cellHeight: Math.round(cellWidth * 74 / 130)

          Repeater {
            model: root.files

            delegate: Item {
              id: thumb
              required property string modelData
              readonly property bool isCurrent: Settings.data.wallpaper.path === modelData
              Layout.preferredWidth: thumbGrid.cellWidth
              Layout.preferredHeight: thumbGrid.cellHeight

              Chamfer {
                anchors.fill: parent
                chamferSize: Tokens.chamferIcon
                cutTopRight: true
                cutBottomLeft: true
                fillColor: Colors.surfaceContainer
                strokeColor: Colors.primary
                strokeWidth: thumb.isCurrent ? 2 : 0
              }

              Image {
                anchors.fill: parent
                anchors.margins: thumb.isCurrent ? 2 : 1
                source: "file://" + thumb.modelData
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
              }

              HoverHandler {
                id: thumbHover
                cursorShape: Qt.PointingHandCursor
              }
              TapHandler {
                onTapped: {
                  Settings.data.wallpaper.path = thumb.modelData;
                  if (Settings.data.wallpaper.autoTheme)
                    Matugen.generateFrom(thumb.modelData);
                }
              }
            }
          }
        }

        NText {
          visible: root.files.length === 0
          text: "No images found in this directory."
          color: Colors.labelText
          size: NText.Size.BodySm
        }
      }

      SettingRow {
        label: "Close on select"
        NToggle {
          checked: Settings.data.wallpaper.closeOnSelect
          onToggled: checked => Settings.data.wallpaper.closeOnSelect = checked
        }
        NText {
          text: "Dismiss the browser (SUPER+W) once a wallpaper is applied"
          color: Colors.labelText
          size: NText.Size.Caption
        }
      }
    }

    SettingsSection {
      title: "Automation"
      description: "Rotate to a new wallpaper from the directory below on a timer."

      SettingRow {
        label: "Auto-cycle"
        NToggle {
          checked: Settings.data.wallpaper.autoCycle
          onToggled: checked => Settings.data.wallpaper.autoCycle = checked
        }
        NText {
          text: "Pick a new wallpaper automatically"
          color: Colors.labelText
          size: NText.Size.Caption
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        opacity: Settings.data.wallpaper.autoCycle ? 1 : 0.4
        enabled: Settings.data.wallpaper.autoCycle

        RowLayout {
          Layout.fillWidth: true
          NText {
            tracking: true
            text: "CYCLE INTERVAL"
            color: Colors.labelText
            size: NText.Size.LabelXs
            Layout.fillWidth: true
          }
          NText {
            text: Settings.data.wallpaper.autoCycleMinutes + " min"
            color: Colors.surfaceText
            size: NText.Size.BodySm
          }
        }

        NSlider {
          Layout.fillWidth: true
          from: 1
          to: 240
          stepSize: 1
          value: Settings.data.wallpaper.autoCycleMinutes
          onMoved: value => Settings.data.wallpaper.autoCycleMinutes = Math.round(value)
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 4
        opacity: Settings.data.wallpaper.autoCycle ? 1 : 0.4
        enabled: Settings.data.wallpaper.autoCycle

        NText {
          tracking: true
          text: "ORDER"
          color: Colors.labelText
          size: NText.Size.LabelXs
        }

        Item {
          Layout.fillWidth: true
        }

        Repeater {
          model: [
            {
              "mode": "random",
              "label": "Random"
            },
            {
              "mode": "sequential",
              "label": "Sequential"
            }
          ]

          delegate: Item {
            id: orderPill
            required property var modelData
            readonly property bool selected: Settings.data.wallpaper.autoCycleMode === modelData.mode
            width: orderLabel.implicitWidth + 20
            height: 26

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: orderPill.selected ? Colors.primary : Colors.surfaceContainer
            }

            NText {
              tracking: true
              id: orderLabel
              anchors.centerIn: parent
              text: orderPill.modelData.label
              color: orderPill.selected ? Colors.primaryText : Colors.surfaceText
              size: NText.Size.LabelXs
            }

            HoverHandler {
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: Settings.data.wallpaper.autoCycleMode = orderPill.modelData.mode
            }
          }
        }
      }
    }

    SettingsSection {
      title: "Wallhaven"
      description: "Used by the wallpaper browser's WALLHAVEN tab (SUPER+W). An API key isn't required for SFW browsing, but is required for NSFW results and to respect your account's own browsing settings."

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        NText {
          tracking: true
          text: "API KEY"
          color: Colors.labelText
          size: NText.Size.LabelXs
        }
        Item {
          Layout.fillWidth: true
          height: 28
          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: Colors.surface
            strokeColor: Colors.primary
            strokeWidth: whApiKeyInput.activeFocus ? Tokens.borderModule : 0
          }
          TextInput {
            id: whApiKeyInput
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            text: Settings.data.wallpaper.wallhavenApiKey
            echoMode: activeFocus ? TextInput.Normal : TextInput.Password
            color: Colors.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodySmSize
            selectByMouse: true
            onEditingFinished: Settings.data.wallpaper.wallhavenApiKey = text

            NText {
              anchors.verticalCenter: parent.verticalCenter
              visible: parent.text === "" && !parent.activeFocus
              text: "wallhaven.cc/settings/account"
              color: Colors.labelText
              size: NText.Size.BodySm
            }
          }
        }
      }
    }
  }
}
