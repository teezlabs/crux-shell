import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Edits the v2 tonal-spot roles (theme.primary/.surface/...) directly —
// editing the legacy mPrimary/mSurface roles here was silently inert.
Flickable {
  id: root
  clip: true
  contentWidth: width
  contentHeight: col.implicitHeight

  readonly property var colorFields: [
    {
      "label": "Primary",
      "key": "primary"
    },
    {
      "label": "Primary container",
      "key": "primaryContainer"
    },
    {
      "label": "On prim. container",
      "key": "primaryContainerText"
    },
    {
      "label": "Tertiary",
      "key": "tertiary"
    },
    {
      "label": "Error",
      "key": "errorTone"
    },
    {
      "label": "Surface",
      "key": "surface"
    },
    {
      "label": "Surface container",
      "key": "surfaceContainer"
    },
    {
      "label": "On surface",
      "key": "surfaceText"
    },
    {
      "label": "Muted text",
      "key": "surfaceTextMuted"
    },
    {
      "label": "Outline",
      "key": "outline"
    }
  ]

  // Full-palette presets — the manual color-picker equivalent of noctalia's
  // scheme picker. Same caveat applies to both: wallpaper theming (see
  // Wallpaper tab) overwrites these on the next apply.
  readonly property var presets: [
    {
      "name": "Mocha",
      "colors": {
        "surface": "#1e1e2e",
        "surfaceContainerLow": "#232334",
        "surfaceContainer": "#313244",
        "surfaceContainerHigh": "#3b3d52",
        "outline": "#45475a",
        "outlineVariant": "#33344a",
        "primary": "#89b4fa",
        "primaryContainer": "#2c3e5c",
        "primaryContainerText": "#c8dcff",
        "tertiary": "#f38ba8",
        "errorTone": "#f38ba8",
        "surfaceText": "#cdd6f4",
        "surfaceTextMuted": "#a6adc8"
      }
    },
    {
      "name": "Nord",
      "colors": {
        "surface": "#2e3440",
        "surfaceContainerLow": "#333a48",
        "surfaceContainer": "#3b4252",
        "surfaceContainerHigh": "#434c5e",
        "outline": "#4c566a",
        "outlineVariant": "#3a4152",
        "primary": "#88c0d0",
        "primaryContainer": "#2e4650",
        "primaryContainerText": "#c3e3ec",
        "tertiary": "#bf616a",
        "errorTone": "#bf616a",
        "surfaceText": "#eceff4",
        "surfaceTextMuted": "#d8dee9"
      }
    },
    {
      "name": "Dracula",
      "colors": {
        "surface": "#282a36",
        "surfaceContainerLow": "#2d2f3d",
        "surfaceContainer": "#44475a",
        "surfaceContainerHigh": "#4d5066",
        "outline": "#6272a4",
        "outlineVariant": "#464a63",
        "primary": "#bd93f9",
        "primaryContainer": "#453465",
        "primaryContainerText": "#e3d1fd",
        "tertiary": "#ff79c6",
        "errorTone": "#ff5555",
        "surfaceText": "#f8f8f2",
        "surfaceTextMuted": "#e2e2f7"
      }
    },
    {
      "name": "Gruvbox",
      "colors": {
        "surface": "#282828",
        "surfaceContainerLow": "#2d2c2a",
        "surfaceContainer": "#3c3836",
        "surfaceContainerHigh": "#46403d",
        "outline": "#504945",
        "outlineVariant": "#3a3532",
        "primary": "#fabd2f",
        "primaryContainer": "#5a4310",
        "primaryContainerText": "#ffe9b3",
        "tertiary": "#fb4934",
        "errorTone": "#fb4934",
        "surfaceText": "#ebdbb2",
        "surfaceTextMuted": "#d5c4a1"
      }
    },
    {
      "name": "Everforest",
      "colors": {
        "surface": "#2b3339",
        "surfaceContainerLow": "#303a40",
        "surfaceContainer": "#3a454a",
        "surfaceContainerHigh": "#445055",
        "outline": "#4a555b",
        "outlineVariant": "#384247",
        "primary": "#a7c080",
        "primaryContainer": "#3d4a30",
        "primaryContainerText": "#dbe9c8",
        "tertiary": "#e67e80",
        "errorTone": "#e67e80",
        "surfaceText": "#d3c6aa",
        "surfaceTextMuted": "#c6d1c1"
      }
    }
  ]

  function applyPreset(colors) {
    for (var key in colors) {
      Settings.data.theme[key] = colors[key];
    }
  }

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

  SettingsSection {
    title: "Presets"
    description: "One-click full palette swap. Live-updated by wallpaper-derived theming too (see Wallpaper tab) — presets and manual edits below are both overwritten the next time a wallpaper is applied."

    Flow {
      Layout.fillWidth: true
      spacing: 8

      Repeater {
        model: root.presets

        delegate: Item {
          id: swatch
          required property var modelData
          width: swatchRow.implicitWidth + 20
          height: 34

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: swatchHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer
            strokeColor: Color.outline
            strokeWidth: Tokens.borderModule
          }

          RowLayout {
            id: swatchRow
            anchors.centerIn: parent
            spacing: 8

            Row {
              spacing: 2
              Repeater {
                model: [swatch.modelData.colors.primary, swatch.modelData.colors.tertiary, swatch.modelData.colors.surface]
                delegate: Rectangle {
                  required property var modelData
                  width: 12
                  height: 12
                  color: modelData
                  border.color: Color.outline
                  border.width: 1
                }
              }
            }

            NText {
              text: swatch.modelData.name
              color: Color.surfaceText
              size: NText.Size.BodySm
            }
          }

          HoverHandler {
            id: swatchHover
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: root.applyPreset(swatch.modelData.colors)
          }
        }
      }
    }
  }

  SettingsSection {
    title: "Manual"
    description: "Edit each color role directly by hex code."

    GridLayout {
      columns: 2
      rowSpacing: 10
      columnSpacing: 20

      Repeater {
        model: root.colorFields

        delegate: RowLayout {
          id: fieldRow
          required property var modelData
          spacing: 10

          Rectangle {
            width: 22
            height: 22
            color: Settings.data.theme[fieldRow.modelData.key]
            border.color: Color.outline
            border.width: 1
          }

          NText {
            text: fieldRow.modelData.label
            color: Color.labelText
            size: NText.Size.BodySm
            Layout.preferredWidth: 110
          }

          Item {
            Layout.preferredWidth: 90
            height: 24

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: Color.surface
              strokeColor: fieldInput.activeFocus ? Color.primary : Color.outline
              strokeWidth: Tokens.borderModule
            }

            TextInput {
              id: fieldInput
              anchors.fill: parent
              anchors.leftMargin: 6
              anchors.rightMargin: 6
              verticalAlignment: Text.AlignVCenter
              text: Settings.data.theme[fieldRow.modelData.key]
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.captionSize
              onEditingFinished: {
                if (/^#[0-9a-fA-F]{6,8}$/.test(text))
                  Settings.data.theme[fieldRow.modelData.key] = text;
              }
            }
          }
        }
      }
    }
  }
  }
}
