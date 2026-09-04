import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
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
        color: installed ? Color.primary : Color.labelText
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
        color: Color.labelText
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
        color: Color.labelText
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
    title: "Region"
    description: "Date/time format shown by the bar's Clock widget (a separate pair from the lock screen's own, under Lock Screen → Appearance)."

    SettingRow {
      label: "Time format"

      NTextInput {
        id: barClockInput
        Layout.preferredWidth: 160
        height: 28
        text: Settings.data.ui.clockFormat
        onEditingFinished: Settings.data.ui.clockFormat = text
      }

      NText {
        text: "Qt date/time format, e.g. HH:mm or h:mm AP"
        color: Color.labelText
        size: NText.Size.Caption
      }
    }

    SettingRow {
      label: "Date format"

      NTextInput {
        id: barDateInput
        Layout.preferredWidth: 160
        height: 28
        text: Settings.data.ui.dateFormat
        onEditingFinished: Settings.data.ui.dateFormat = text
      }

      NText {
        text: "Shown uppercased, e.g. WED 25 AUG"
        color: Color.labelText
        size: NText.Size.Caption
      }
    }
  }

  SettingsSection {
    title: "Input"
    description: "Applied live via hyprctl — takes effect immediately, no reload needed."

    SettingRow {
      label: "Reverse scrolling"
      NToggle {
        checked: Settings.data.general.reverseScroll
        onToggled: checked => Settings.data.general.reverseScroll = checked
      }
      NText {
        text: "Natural scroll direction (input:natural_scroll)"
        color: Color.labelText
        size: NText.Size.Caption
      }
    }
  }

  SettingsSection {
    title: "crux"
    description: "Where crux's config and settings files live on disk."

    GridLayout {
      columns: 2
      rowSpacing: 8
      columnSpacing: 16

      NText {
        text: "Config"
        color: Color.labelText
        size: NText.Size.BodySm
      }
      NText {
        text: Quickshell.shellDir
        color: Color.surfaceText
        size: NText.Size.BodySm
      }

      NText {
        text: "Settings"
        color: Color.labelText
        size: NText.Size.BodySm
      }
      NText {
        text: Settings.settingsFile
        color: Color.surfaceText
        size: NText.Size.BodySm
      }
    }
  }

  SettingsSection {
    title: "Reload"
    description: "Reloads every widget and settings page — use after editing a .qml file by hand outside this session."

    RowLayout {
      spacing: 10

      NButton {
        text: "Restart crux"
        onClicked: Quickshell.execDetached(["bash", "-c", "pkill -f 'qs -c crux'; sleep 0.5; nohup qs -c crux >/dev/null 2>&1 & disown"])
      }
    }
  }
  }
}
