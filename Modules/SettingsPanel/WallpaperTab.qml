import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Wallpaper picker + matugen-driven theme generation, native to crux.
Flickable {
  id: root
  clip: true
  contentWidth: width
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
          color: Color.labelText
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
          color: Color.labelText
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
                fillColor: schemePill.selected ? Color.primaryContainer : Color.surfaceContainer
                strokeColor: schemePill.selected ? Color.primary : Color.outline
                strokeWidth: Tokens.borderModule
              }

              NText {
                tracking: true
                id: schemeLabel
                anchors.centerIn: parent
                text: schemePill.modelData.label
                color: schemePill.selected ? Color.primaryContainerText : Color.surfaceText
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

        Item {
          Layout.preferredWidth: regenLabel.implicitWidth + 24
          height: 30
          enabled: Settings.data.wallpaper.path !== "" && !Matugen.running
          opacity: enabled ? 1 : 0.4

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: regenHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer
            strokeColor: Color.outline
            strokeWidth: Tokens.borderModule
          }

          NText {
            id: regenLabel
            anchors.centerIn: parent
            text: Matugen.running ? "Generating…" : "Regenerate colors now"
            color: Color.surfaceText
            size: NText.Size.BodySm
          }

          HoverHandler {
            id: regenHover
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: Matugen.generateFrom(Settings.data.wallpaper.path)
          }
        }

        Item {
          Layout.preferredWidth: cycleLabel.implicitWidth + 24
          height: 30
          enabled: Settings.data.wallpaper.path !== "" && !Matugen.running
          opacity: enabled ? 1 : 0.4

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: cycleHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer
            strokeColor: Color.outline
            strokeWidth: Tokens.borderModule
          }

          NText {
            id: cycleLabel
            anchors.centerIn: parent
            text: "Cycle color (" + Settings.data.wallpaper.matugenColorIndex + "/4)"
            color: Color.surfaceText
            size: NText.Size.BodySm
          }

          HoverHandler {
            id: cycleHover
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: Matugen.cycleColorIndex()
          }
        }

        NText {
          visible: Matugen.lastError !== ""
          text: Matugen.lastError
          color: Color.error
          size: NText.Size.Caption
          wrapMode: Text.WordWrap
          Layout.fillWidth: true
        }
      }
    }

    SettingsSection {
      title: "Switch transition"
      description: "Animated shader transition when the wallpaper changes. Check more than one to pick randomly each time."

      Flow {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
          model: [
            {
              "key": "fade",
              "label": "Fade"
            },
            {
              "key": "wipe",
              "label": "Wipe"
            },
            {
              "key": "disc",
              "label": "Disc"
            },
            {
              "key": "stripes",
              "label": "Stripes"
            },
            {
              "key": "pixelate",
              "label": "Pixelate"
            },
            {
              "key": "honeycomb",
              "label": "Honeycomb"
            }
          ]

          delegate: Item {
            id: transPill
            required property var modelData
            readonly property bool selected: Settings.data.wallpaper.transitionType.indexOf(modelData.key) !== -1
            width: transLabel.implicitWidth + 20
            height: 26

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: transPill.selected ? Color.primaryContainer : Color.surfaceContainer
              strokeColor: transPill.selected ? Color.primary : Color.outline
              strokeWidth: Tokens.borderModule
            }

            NText {
              tracking: true
              id: transLabel
              anchors.centerIn: parent
              text: transPill.modelData.label
              color: transPill.selected ? Color.primaryContainerText : Color.surfaceText
              size: NText.Size.LabelXs
            }

            HoverHandler {
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: {
                var list = Settings.data.wallpaper.transitionType.slice();
                var idx = list.indexOf(transPill.modelData.key);
                if (idx !== -1) {
                  if (list.length > 1)
                    list.splice(idx, 1);
                } else {
                  list.push(transPill.modelData.key);
                }
                Settings.data.wallpaper.transitionType = list;
              }
            }
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        RowLayout {
          Layout.fillWidth: true
          NText {
            tracking: true
            text: "DURATION"
            color: Color.labelText
            size: NText.Size.LabelXs
            Layout.fillWidth: true
          }
          NText {
            text: Settings.data.wallpaper.transitionDuration + " ms"
            color: Color.surfaceText
            size: NText.Size.BodySm
          }
        }

        NSlider {
          Layout.fillWidth: true
          from: 200
          to: 2000
          stepSize: 50
          value: Settings.data.wallpaper.transitionDuration
          onMoved: value => Settings.data.wallpaper.transitionDuration = Math.round(value)
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        RowLayout {
          Layout.fillWidth: true
          NText {
            tracking: true
            text: "EDGE SMOOTHNESS"
            color: Color.labelText
            size: NText.Size.LabelXs
            Layout.fillWidth: true
          }
          NText {
            text: Settings.data.wallpaper.transitionEdgeSmoothness.toFixed(2)
            color: Color.surfaceText
            size: NText.Size.BodySm
          }
        }

        NSlider {
          Layout.fillWidth: true
          from: 0
          to: 0.3
          stepSize: 0.01
          value: Settings.data.wallpaper.transitionEdgeSmoothness
          onMoved: value => Settings.data.wallpaper.transitionEdgeSmoothness = value
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
          color: Color.labelText
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
            color: Color.labelText
            size: NText.Size.LabelXs
            Layout.fillWidth: true
          }
          NText {
            text: Settings.data.wallpaper.autoCycleMinutes + " min"
            color: Color.surfaceText
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
          color: Color.labelText
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
              fillColor: orderPill.selected ? Color.primaryContainer : Color.surfaceContainer
              strokeColor: orderPill.selected ? Color.primary : Color.outline
              strokeWidth: Tokens.borderModule
            }

            NText {
              tracking: true
              id: orderLabel
              anchors.centerIn: parent
              text: orderPill.modelData.label
              color: orderPill.selected ? Color.primaryContainerText : Color.surfaceText
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
          color: Color.labelText
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
            fillColor: Color.surface
            strokeColor: whApiKeyInput.activeFocus ? Color.primary : Color.outline
            strokeWidth: Tokens.borderModule
          }
          TextInput {
            id: whApiKeyInput
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            text: Settings.data.wallpaper.wallhavenApiKey
            echoMode: activeFocus ? TextInput.Normal : TextInput.Password
            color: Color.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodySmSize
            selectByMouse: true
            onEditingFinished: Settings.data.wallpaper.wallhavenApiKey = text

            NText {
              anchors.verticalCenter: parent.verticalCenter
              visible: parent.text === "" && !parent.activeFocus
              text: "wallhaven.cc/settings/account"
              color: Color.labelText
              size: NText.Size.BodySm
            }
          }
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
              fillColor: tplPill.selected ? Color.primaryContainer : Color.surfaceContainer
              strokeColor: tplPill.selected ? Color.primary : Color.outline
              strokeWidth: Tokens.borderModule
            }

            NText {
              tracking: true
              id: tplLabel
              anchors.centerIn: parent
              text: tplPill.modelData.label
              color: tplPill.selected ? Color.primaryContainerText : Color.surfaceText
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

    SettingsSection {
      title: "Wallpapers"
      description: "Current: " + (Settings.data.wallpaper.path || "(none set)")

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 10

        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Item {
            Layout.fillWidth: true
            height: 28

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: Color.surface
              strokeColor: dirInput.activeFocus ? Color.primary : Color.outline
              strokeWidth: Tokens.borderModule
            }

            TextInput {
              id: dirInput
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8
              verticalAlignment: Text.AlignVCenter
              text: Settings.data.wallpaper.directory
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
              selectByMouse: true
              onEditingFinished: {
                Settings.data.wallpaper.directory = text;
                root.rescan();
              }
            }
          }

          NText {
            text: root.files.length + " found"
            color: Color.labelText
            size: NText.Size.Caption
          }
        }

        GridLayout {
          Layout.fillWidth: true
          columns: 5
          rowSpacing: 8
          columnSpacing: 8

          Repeater {
            model: root.files

            delegate: Item {
              id: thumb
              required property string modelData
              readonly property bool isCurrent: Settings.data.wallpaper.path === modelData
              Layout.preferredWidth: 130
              Layout.preferredHeight: 74

              Chamfer {
                anchors.fill: parent
                chamferSize: Tokens.chamferIcon
                cutTopRight: true
                cutBottomLeft: true
                fillColor: Color.surfaceContainer
                strokeColor: thumb.isCurrent ? Color.primary : (thumbHover.hovered ? Color.alpha(Color.primary, 0.5) : Color.outline)
                strokeWidth: thumb.isCurrent ? 2 : Tokens.borderModule
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
          color: Color.labelText
          size: NText.Size.BodySm
        }
      }
    }
  }
}
