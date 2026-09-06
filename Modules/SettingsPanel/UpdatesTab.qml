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
      title: "Checking"
      description: "How often the package count is refreshed, and whether the widget stays on the bar with nothing pending."

      SettingRow {
        label: "Hide when 0"
        NToggle {
          checked: Settings.data.updates.hideOnZero
          onToggled: checked => Settings.data.updates.hideOnZero = checked
        }
      }

      SettingRow {
        label: "Interval"
        NValueSlider {
          from: 5
          to: 300
          stepSize: 5
          value: Settings.data.updates.intervalMinutes
          sliderWidth: 200
          readoutText: Settings.data.updates.intervalMinutes + " min"
          onMoved: value => Settings.data.updates.intervalMinutes = Math.round(value)
        }
      }
    }

    SettingsSection {
      title: "Commands"
      description: "Left blank, updates run through yay when it's installed and pacman otherwise. The terminal wrapper is what opens for an interactive upgrade."

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        NText {
          tracking: true
          text: "TERMINAL  (\"{}\" = the command to run)"
          color: Color.labelText
          size: NText.Size.LabelXs
        }
        NTextInput {
          Layout.fillWidth: true
          height: 28
          text: Settings.data.updates.terminalCommand
          onEditingFinished: Settings.data.updates.terminalCommand = text
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        NText {
          tracking: true
          text: "COUNT COMMAND"
          color: Color.labelText
          size: NText.Size.LabelXs
        }
        NTextInput {
          Layout.fillWidth: true
          height: 28
          placeholderText: "checkupdates | wc -l"
          text: Settings.data.updates.customCountCmd
          onEditingFinished: Settings.data.updates.customCountCmd = text
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        NText {
          tracking: true
          text: "UPDATE COMMAND"
          color: Color.labelText
          size: NText.Size.LabelXs
        }
        NTextInput {
          Layout.fillWidth: true
          height: 28
          placeholderText: "yay -Syu"
          text: Settings.data.updates.customUpdateCmd
          onEditingFinished: Settings.data.updates.customUpdateCmd = text
        }
      }
    }
  }
}
