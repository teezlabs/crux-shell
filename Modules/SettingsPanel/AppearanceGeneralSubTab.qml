import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

NScrollView {
  id: root
  contentHeight: col.implicitHeight

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

  SettingsSection {
    title: "Interface"
    description: "The font and overall size used across the shell."

    SettingRow {
      label: "Font family"

      NComboBox {
        Layout.preferredWidth: 200
        height: 28
        searchable: true
        popupMaxHeight: 260
        model: FontService.families
        currentKey: Settings.data.ui.fontFamily
        placeholder: "Pick a font"
        onSelected: key => Settings.data.ui.fontFamily = key
      }

      NText {
        readonly property bool installed: FontService.families.indexOf(Settings.data.ui.fontFamily) !== -1
        text: installed ? "✓ installed" : "not installed — falls back"
        color: installed ? Colors.primary : Colors.labelText
        size: NText.Size.Caption
      }
    }

    SettingRow {
      label: "Monospaced font"

      NComboBox {
        Layout.preferredWidth: 200
        height: 28
        searchable: true
        popupMaxHeight: 260
        // Only fixed-pitch faces — the list is built on first open, since
        // detecting them walks every installed family.
        model: FontService.monoFamilies
        currentKey: Settings.data.ui.monoFontFamily
        placeholder: "Pick a font"
        onOpenedChanged: if (opened) FontService.ensureMono()
        onSelected: key => Settings.data.ui.monoFontFamily = key
      }

      NText {
        text: "Used by the keybinds viewer and hook command fields"
        color: Colors.labelText
        size: NText.Size.Caption
      }
    }

    SettingRow {
      label: "Avatar image"

      NTextInput {
        id: avatarInput
        Layout.fillWidth: true
        height: 28
        text: Settings.data.general.avatarImage
        onEditingFinished: Settings.data.general.avatarImage = text
      }

      NText {
        text: "Empty = the Arch logo in Control Center's header"
        color: Colors.labelText
        size: NText.Size.Caption
      }
    }

    SettingRow {
      label: "UI scale"

      NValueSlider {
        from: 0.8
        to: 1.4
        stepSize: 0.05
        value: Settings.data.ui.fontScale
        sliderWidth: 160
        readoutText: Math.round(Settings.data.ui.fontScale * 100) + "%"
        onMoved: value => Settings.data.ui.fontScale = value
      }
    }
  }

  SettingsSection {
    title: "Window corners"
    description: "Which corners Hyprland cuts on every window. Off goes back to Hyprland's own rounding."

    SettingRow {
      label: "Chamfer windows"

      NToggle {
        checked: Settings.data.windowCorners.enabled
        onToggled: checked => Settings.data.windowCorners.enabled = checked
      }
    }

    SettingRow {
      label: "Cut corners"

      Item {
        id: cornerPicker
        enabled: Settings.data.windowCorners.enabled
        implicitWidth: 72
        implicitHeight: 48

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferPanel
          cutTopLeft: Settings.data.windowCorners.cutTopLeft
          cutTopRight: Settings.data.windowCorners.cutTopRight
          cutBottomRight: Settings.data.windowCorners.cutBottomRight
          cutBottomLeft: Settings.data.windowCorners.cutBottomLeft
          fillColor: Colors.surfaceContainerHigh
          strokeColor: cornerPicker.enabled ? Colors.primary : Colors.outline
          strokeWidth: Tokens.borderModule
        }

        Repeater {
          model: ["cutTopLeft", "cutTopRight", "cutBottomLeft", "cutBottomRight"]

          Item {
            required property string modelData
            required property int index
            x: index % 2 === 0 ? 0 : cornerPicker.width / 2
            y: index < 2 ? 0 : cornerPicker.height / 2
            width: cornerPicker.width / 2
            height: cornerPicker.height / 2

            HoverHandler {
              cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
              onTapped: Settings.data.windowCorners[modelData] = !Settings.data.windowCorners[modelData]
            }
          }
        }
      }

      NText {
        text: "Click a corner to cut or square it"
        color: Colors.labelText
        size: NText.Size.Caption
      }
    }
  }
  }
}
