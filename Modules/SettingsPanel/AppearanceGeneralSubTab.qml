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
  }
}
