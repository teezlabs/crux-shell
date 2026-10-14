import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Edits the v2 tonal-spot roles (theme.primary/.surface/...) directly —
// editing the legacy mPrimary/mSurface roles here was silently inert.
NScrollView {
  id: root
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
        model: ColorSchemes.schemes

        delegate: Item {
          id: swatch
          required property var modelData
          readonly property bool applied: Settings.data.theme.colorScheme === swatch.modelData.name
          width: swatchRow.implicitWidth + 20
          height: 34

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: swatch.applied ? Colors.alpha(Colors.primary, 0.2) : (swatchHover.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer)
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
                  border.color: Colors.outline
                  border.width: 1
                }
              }
            }

            NText {
              text: swatch.modelData.name
              color: Colors.surfaceText
              size: NText.Size.BodySm
            }
          }

          HoverHandler {
            id: swatchHover
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: ColorSchemes.apply(swatch.modelData.name)
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
            border.color: Colors.outline
            border.width: 1
          }

          NText {
            text: fieldRow.modelData.label
            color: Colors.labelText
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
              fillColor: Colors.surface
              strokeColor: Colors.primary
              strokeWidth: fieldInput.activeFocus ? Tokens.borderModule : 0
            }

            TextInput {
              id: fieldInput
              anchors.fill: parent
              anchors.leftMargin: 6
              anchors.rightMargin: 6
              verticalAlignment: Text.AlignVCenter
              text: Settings.data.theme[fieldRow.modelData.key]
              color: Colors.surfaceText
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
