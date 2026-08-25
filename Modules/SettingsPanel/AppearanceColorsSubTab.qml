import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.SettingsPanel.Controls

ColumnLayout {
  id: root
  spacing: 20

  readonly property var colorFields: [
    {
      "label": "Primary",
      "key": "mPrimary"
    },
    {
      "label": "On primary",
      "key": "mOnPrimary"
    },
    {
      "label": "Secondary",
      "key": "mSecondary"
    },
    {
      "label": "On secondary",
      "key": "mOnSecondary"
    },
    {
      "label": "Surface",
      "key": "mSurface"
    },
    {
      "label": "On surface",
      "key": "mOnSurface"
    },
    {
      "label": "Surface var.",
      "key": "mSurfaceVariant"
    },
    {
      "label": "On surf. var.",
      "key": "mOnSurfaceVariant"
    },
    {
      "label": "Outline",
      "key": "mOutline"
    },
    {
      "label": "Error",
      "key": "mError"
    }
  ]

  // Full-palette presets — the manual color-picker equivalent of noctalia's
  // scheme picker (Tabs/ColorScheme). Same caveat applies to both: wallpaper
  // theming (see Wallpaper tab) overwrites these on the next apply.
  readonly property var presets: [
    {
      "name": "Mocha",
      "colors": {
        "mPrimary": "#89b4fa",
        "mOnPrimary": "#1e1e2e",
        "mSecondary": "#f38ba8",
        "mOnSecondary": "#1e1e2e",
        "mSurface": "#1e1e2e",
        "mOnSurface": "#cdd6f4",
        "mSurfaceVariant": "#313244",
        "mOnSurfaceVariant": "#a6adc8",
        "mOutline": "#45475a",
        "mError": "#f38ba8"
      }
    },
    {
      "name": "Nord",
      "colors": {
        "mPrimary": "#88c0d0",
        "mOnPrimary": "#2e3440",
        "mSecondary": "#bf616a",
        "mOnSecondary": "#2e3440",
        "mSurface": "#2e3440",
        "mOnSurface": "#eceff4",
        "mSurfaceVariant": "#3b4252",
        "mOnSurfaceVariant": "#d8dee9",
        "mOutline": "#4c566a",
        "mError": "#bf616a"
      }
    },
    {
      "name": "Dracula",
      "colors": {
        "mPrimary": "#bd93f9",
        "mOnPrimary": "#282a36",
        "mSecondary": "#ff79c6",
        "mOnSecondary": "#282a36",
        "mSurface": "#282a36",
        "mOnSurface": "#f8f8f2",
        "mSurfaceVariant": "#44475a",
        "mOnSurfaceVariant": "#e2e2f7",
        "mOutline": "#6272a4",
        "mError": "#ff5555"
      }
    },
    {
      "name": "Gruvbox",
      "colors": {
        "mPrimary": "#fabd2f",
        "mOnPrimary": "#282828",
        "mSecondary": "#fb4934",
        "mOnSecondary": "#282828",
        "mSurface": "#282828",
        "mOnSurface": "#ebdbb2",
        "mSurfaceVariant": "#3c3836",
        "mOnSurfaceVariant": "#d5c4a1",
        "mOutline": "#504945",
        "mError": "#fb4934"
      }
    },
    {
      "name": "Everforest",
      "colors": {
        "mPrimary": "#a7c080",
        "mOnPrimary": "#2b3339",
        "mSecondary": "#e67e80",
        "mOnSecondary": "#2b3339",
        "mSurface": "#2b3339",
        "mOnSurface": "#d3c6aa",
        "mSurfaceVariant": "#3a454a",
        "mOnSurfaceVariant": "#c6d1c1",
        "mOutline": "#4a555b",
        "mError": "#e67e80"
      }
    }
  ]

  function applyPreset(colors) {
    for (var key in colors) {
      Settings.data.theme[key] = colors[key];
    }
  }

  SettingsSection {
    title: "Presets"
    description: "One-click full palette swap. Live-updated by wallpaper-derived theming too (see Wallpaper tab) — presets and manual edits below are both overwritten the next time a wallpaper is applied."

    Flow {
      Layout.fillWidth: true
      spacing: 8

      Repeater {
        model: root.presets

        delegate: Rectangle {
          id: swatch
          required property var modelData
          width: swatchRow.implicitWidth + 20
          height: 34
          radius: Style.radiusXS
          color: swatchHover.hovered ? Color.alpha(Color.mPrimary, 0.16) : Color.mSurface
          border.color: Color.alpha(Color.mPrimary, 0.55)
          border.width: 1
          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
            }
          }

          RowLayout {
            id: swatchRow
            anchors.centerIn: parent
            spacing: 8

            Row {
              spacing: 2
              Repeater {
                model: [swatch.modelData.colors.mPrimary, swatch.modelData.colors.mSecondary, swatch.modelData.colors.mSurface]
                delegate: Rectangle {
                  width: 12
                  height: 12
                  radius: 6
                  color: modelData
                  border.color: Color.mOutline
                  border.width: 1
                }
              }
            }

            Text {
              text: swatch.modelData.name
              color: Color.mOnSurface
              font.family: Settings.data.ui.fontFamily
              font.pixelSize: Style.fontSizeS
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
            radius: Style.radiusXXS
            color: Settings.data.theme[fieldRow.modelData.key]
            border.color: Color.mOutline
            border.width: 1
          }

          Text {
            text: fieldRow.modelData.label
            color: Color.mOnSurfaceVariant
            font.family: Settings.data.ui.fontFamily
            font.pixelSize: Style.fontSizeS
            Layout.preferredWidth: 80
          }

          TextInput {
            Layout.preferredWidth: 90
            text: Settings.data.theme[fieldRow.modelData.key]
            color: Color.mOnSurface
            font.family: Settings.data.ui.fontFamily
            font.pixelSize: Style.fontSizeS
            onEditingFinished: {
              if (/^#[0-9a-fA-F]{6,8}$/.test(text))
                Settings.data.theme[fieldRow.modelData.key] = text;
            }

            Rectangle {
              z: -1
              anchors.fill: parent
              anchors.margins: -4
              color: Color.mSurface
              radius: Style.radiusXXS
            }
          }
        }
      }
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
