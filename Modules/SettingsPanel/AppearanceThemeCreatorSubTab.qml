import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Widgets
import "../../Commons/Oklch.js" as Oklch

// Theme creator (after lyne-dots): seed a palette from an accent and a mood, the current theme or a preset; tweak any
// role in OKLCH; preview it; then try it on the shell or save it as a theme beside the presets.
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  // role -> hex for every ColorSchemes role.
  property var draft: ({})
  property string source: "accent"
  property string accent: Settings.data.theme.primary
  property string mood: "balanced"
  property string preset: ""
  property string editing: "primary"
  property string themeName: ""

  readonly property var roleLabels: ({
      "surface": "Surface",
      "surfaceContainerLow": "Container low",
      "surfaceContainer": "Container",
      "surfaceContainerHigh": "Container high",
      "outline": "Outline",
      "outlineVariant": "Outline variant",
      "primary": "Primary",
      "primaryContainer": "Primary container",
      "primaryContainerText": "On primary container",
      "tertiary": "Tertiary",
      "errorTone": "Error",
      "surfaceText": "Text",
      "surfaceTextMuted": "Muted text",
      "primaryText": "On primary",
      "errorText": "On error"
    })

  function fromCurrent() {
    const out = {};
    for (const r of ColorSchemes.roles)
      out[r] = String(Settings.data.theme[r] || "");
    return out;
  }

  // Rebuilds the draft from the chosen starting point.
  function seed() {
    if (root.source === "accent") {
      root.draft = Oklch.generate(root.accent, root.mood);
    } else if (root.source === "current") {
      root.draft = root.fromCurrent();
    } else {
      const s = ColorSchemes.schemes.find(x => x.name === root.preset);
      const base = root.fromCurrent();
      root.draft = s ? Object.assign(base, s.colors) : base;
    }
  }

  function setRole(role, hex) {
    const next = Object.assign({}, root.draft);
    next[role] = hex;
    root.draft = next;
  }

  function c(role) {
    return root.draft[role] || "#000000";
  }
  // color-typed, so Colors.mix can read their channels.
  readonly property color previewSurface: root.c("surface")
  readonly property color previewPrimary: root.c("primary")

  Component.onCompleted: seed()

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

    SettingsSection {
      title: "Start from"
      description: "Pick where the new theme's colours come from. Changing this replaces the draft below."

      SettingRow {
        label: "Source"
        NSegmented {
          model: [
            {
              "key": "accent",
              "label": "Accent"
            },
            {
              "key": "current",
              "label": "Current"
            },
            {
              "key": "preset",
              "label": "Preset"
            }
          ]
          currentKey: root.source
          tileWidth: 80
          uppercase: false
          onSelected: key => {
            root.source = key;
            if (key === "preset" && root.preset === "" && ColorSchemes.schemes.length > 0)
              root.preset = ColorSchemes.schemes[0].name;
            root.seed();
          }
        }
      }

      SettingRow {
        visible: root.source === "accent"
        label: "Mood"
        description: "How much colour the surfaces and the accent carry"
        NSegmented {
          model: [
            {
              "key": "muted",
              "label": "Muted"
            },
            {
              "key": "balanced",
              "label": "Balanced"
            },
            {
              "key": "vivid",
              "label": "Vivid"
            }
          ]
          currentKey: root.mood
          tileWidth: 80
          uppercase: false
          onSelected: key => {
            root.mood = key;
            root.seed();
          }
        }
      }

      SettingRow {
        visible: root.source === "preset"
        label: "Preset"
        NComboBox {
          Layout.preferredWidth: 200
          model: ColorSchemes.schemes.map(s => s.name)
          currentKey: root.preset
          onSelected: key => {
            root.preset = key;
            root.seed();
          }
        }
      }

      ColumnLayout {
        visible: root.source === "accent"
        Layout.fillWidth: true
        spacing: Tokens.spaceSm

        NText {
          text: "ACCENT"
          tracking: true
          size: NText.Size.LabelXs
          color: Colors.labelText
        }
        OklchPicker {
          Layout.fillWidth: true
          hex: root.accent
          onPicked: hex => {
            root.accent = hex;
            root.seed();
          }
        }
      }
    }

    SettingsSection {
      title: "Preview"
      description: "The draft on a mock panel. Nothing on the shell changes until you try it or save it."

      // ---- Mock panel drawn in the draft's colours ----
      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 190

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferPanel
          cutTopRight: true
          cutBottomLeft: true
          fillColor: root.c("surface")
          strokeColor: root.c("outline")
          strokeWidth: Tokens.borderPanel
        }

        // Bar strip, tinted toward the accent like Colors.barSurface.
        Rectangle {
          x: Tokens.spaceLg
          y: Tokens.spaceLg
          width: parent.width - Tokens.spaceLg * 2
          height: 26
          color: Colors.mix(root.previewSurface, root.previewPrimary, 0.08)
          border.color: root.c("outlineVariant")
          border.width: Tokens.borderModule

          Row {
            anchors.verticalCenter: parent.verticalCenter
            x: Tokens.spaceMd
            spacing: Tokens.spaceSm
            Repeater {
              model: 5
              Rectangle {
                required property int index
                width: 16
                height: 16
                color: index === 0 ? root.c("primary") : root.c("surfaceContainerHigh")
                NText {
                  anchors.centerIn: parent
                  text: String(parent.index + 1)
                  size: NText.Size.LabelXs
                  color: parent.index === 0 ? root.c("primaryText") : root.c("surfaceTextMuted")
                }
              }
            }
          }
          NText {
            anchors.right: parent.right
            anchors.rightMargin: Tokens.spaceMd
            anchors.verticalCenter: parent.verticalCenter
            text: "02:45"
            size: NText.Size.Caption
            color: root.c("surfaceText")
          }
        }

        // A card with text, a slider, and buttons.
        Item {
          x: Tokens.spaceLg
          y: Tokens.spaceLg + 26 + Tokens.spaceMd
          width: parent.width - Tokens.spaceLg * 2
          height: parent.height - y - Tokens.spaceLg

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferModule
            cutTopRight: true
            cutBottomLeft: true
            fillColor: root.c("surfaceContainer")
            strokeColor: root.c("outlineVariant")
            strokeWidth: Tokens.borderModule
          }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.spaceMd
            spacing: Tokens.spaceSm

            NText {
              text: "NOW PLAYING"
              tracking: true
              size: NText.Size.LabelXs
              color: root.c("surfaceTextMuted")
            }
            NText {
              text: "A dance under the Sun"
              size: NText.Size.BodySm
              font.weight: Font.DemiBold
              color: root.c("surfaceText")
            }
            Item {
              Layout.fillWidth: true
              Layout.preferredHeight: 10
              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: root.c("surfaceContainerHigh")
              }
              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * 0.4
                height: 4
                radius: 2
                color: root.c("primary")
              }
            }
            Item {
              Layout.fillHeight: true
            }
            RowLayout {
              spacing: Tokens.spaceSm

              Repeater {
                model: [
                  {
                    "fill": "primary",
                    "text": "primaryText",
                    "label": "Primary"
                  },
                  {
                    "fill": "primaryContainer",
                    "text": "primaryContainerText",
                    "label": "Container"
                  },
                  {
                    "fill": "tertiary",
                    "text": "primaryText",
                    "label": "Tertiary"
                  },
                  {
                    "fill": "errorTone",
                    "text": "errorText",
                    "label": "Error"
                  }
                ]
                Item {
                  required property var modelData
                  implicitWidth: chipLabel.implicitWidth + Tokens.spaceLg * 2
                  implicitHeight: 24
                  Chamfer {
                    anchors.fill: parent
                    chamferSize: Tokens.chamferIcon
                    cutTopRight: true
                    cutBottomLeft: true
                    fillColor: root.c(parent.modelData.fill)
                  }
                  NText {
                    id: chipLabel
                    anchors.centerIn: parent
                    text: parent.modelData.label
                    size: NText.Size.LabelXs
                    font.weight: Font.DemiBold
                    color: root.c(parent.modelData.text)
                  }
                }
              }
            }
          }
        }
      }
    }

    SettingsSection {
      title: "Colours"
      description: "Click a role to edit it."

      GridLayout {
        Layout.fillWidth: true
        columns: 3
        rowSpacing: Tokens.spaceSm
        columnSpacing: Tokens.spaceSm

        Repeater {
          model: ColorSchemes.roles

          delegate: Item {
            id: roleTile
            required property string modelData
            readonly property bool active: root.editing === modelData
            Layout.fillWidth: true
            implicitHeight: 34

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: roleHover.hovered || roleTile.active ? Colors.surfaceContainerHigh : Colors.surfaceContainer
              strokeColor: roleTile.active ? Colors.primary : Colors.outlineVariant
              strokeWidth: roleTile.active ? Tokens.borderMarker : Tokens.borderModule
            }
            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Tokens.spaceSm
              anchors.rightMargin: Tokens.spaceSm
              spacing: Tokens.spaceSm
              Rectangle {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                color: root.c(roleTile.modelData)
                border.color: Colors.outline
                border.width: Tokens.borderModule
              }
              NText {
                Layout.fillWidth: true
                text: root.roleLabels[roleTile.modelData] || roleTile.modelData
                size: NText.Size.Caption
                color: Colors.surfaceText
                elide: Text.ElideRight
              }
            }
            HoverHandler {
              id: roleHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: root.editing = roleTile.modelData
            }
          }
        }
      }

      NText {
        text: (root.roleLabels[root.editing] || root.editing).toUpperCase()
        tracking: true
        size: NText.Size.LabelXs
        color: Colors.labelText
        Layout.topMargin: Tokens.spaceSm
      }
      OklchPicker {
        Layout.fillWidth: true
        hex: root.c(root.editing)
        onPicked: hex => root.setRole(root.editing, hex)
      }
    }

    SettingsSection {
      title: "Use it"
      description: "Try it on the shell, or save it: saved themes appear in Colors › Presets, and live in ~/.config/crux/themes."

      SettingRow {
        label: "Name"
        NTextInput {
          Layout.preferredWidth: 220
          height: 28
          placeholderText: "My theme"
          text: root.themeName
          onTextEdited: t => root.themeName = t
          onEditingFinished: root.themeName = text
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spaceMd

        Item {
          Layout.fillWidth: true
        }
        NButton {
          text: "Try on the shell"
          onClicked: ColorSchemes.applyPalette("Draft", root.draft)
        }
        NButton {
          text: "Save and apply"
          variant: "accent"
          enabled: ColorSchemes.fileNameFor(root.themeName) !== ""
          onClicked: {
            ColorSchemes.save(root.themeName, root.draft);
            ColorSchemes.applyPalette(root.themeName.trim(), root.draft);
          }
        }
      }
    }
  }
}
