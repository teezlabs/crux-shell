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
        color: Colors.labelText
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
        color: Colors.labelText
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
        color: Colors.labelText
        size: NText.Size.Caption
      }
    }
  }
  }
}
