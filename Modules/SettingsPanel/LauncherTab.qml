import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Settings for the app Launcher (SUPER+A) and Clipboard history (SUPER+V)
// popups — both already work with hardcoded behavior; this exposes what
// was actually constant before (result count, match style, run-command
// prefix, history size).
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

  SettingsSection {
    title: "Launcher"
    description: "The app launcher opened with SUPER+A."

    SettingRow {
      label: "Fuzzy matching"
      NToggle {
        checked: Settings.data.launcher.fuzzyMatch
        onToggled: checked => Settings.data.launcher.fuzzyMatch = checked
      }
      NText {
        text: "Off = plain substring search"
        color: Color.labelText
        size: NText.Size.Caption
      }
    }

    SettingRow {
      label: "Sort by most used"
      NToggle {
        checked: Settings.data.launcher.sortByMostUsed
        onToggled: checked => Settings.data.launcher.sortByMostUsed = checked
      }
      NText {
        text: "Empty-query list only — a real search still sorts by match quality"
        color: Color.labelText
        size: NText.Size.Caption
      }
    }

    SettingRow {
      label: "Result limit"
      NValueSlider {
        from: 5
        to: 60
        stepSize: 1
        value: Settings.data.launcher.resultLimit
        sliderWidth: 160
        readoutText: Settings.data.launcher.resultLimit
        onMoved: value => Settings.data.launcher.resultLimit = Math.round(value)
      }
    }

    SettingRow {
      label: "Run-command prefix"

      NTextInput {
        id: prefixInput
        Layout.preferredWidth: 80
        height: 28
        text: Settings.data.launcher.execPrefix
        onEditingFinished: Settings.data.launcher.execPrefix = text
      }

      NText {
        text: "Typing this first runs the rest as a shell command (sh -c) instead of searching apps. Empty disables it."
        color: Color.labelText
        size: NText.Size.Caption
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
    }
  }

  SettingsSection {
    title: "Clipboard"
    description: "The clipboard history popup opened with SUPER+V, backed by cliphist."

    SettingRow {
      label: "History size"
      NValueSlider {
        from: 10
        to: 200
        stepSize: 10
        value: Settings.data.clipboard.historyLimit
        sliderWidth: 160
        readoutText: Settings.data.clipboard.historyLimit + " entries"
        onMoved: value => Settings.data.clipboard.historyLimit = Math.round(value)
      }
    }

    NText {
      text: "Trims how many of cliphist's own entries are shown/kept in the popup — doesn't touch cliphist's own database or run a wipe."
      color: Color.labelText
      size: NText.Size.Caption
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }
  }
}
