import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls

// Settings for the app Launcher (SUPER+A) and Clipboard history (SUPER+V)
// popups — both already work with hardcoded behavior; this exposes what
// was actually constant before (result count, match style, run-command
// prefix, history size).
Flickable {
  id: root
  clip: true
  contentWidth: width
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
      Text {
        text: "Off = plain substring search"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.captionSize
      }
    }

    SettingRow {
      label: "Sort by most used"
      NToggle {
        checked: Settings.data.launcher.sortByMostUsed
        onToggled: checked => Settings.data.launcher.sortByMostUsed = checked
      }
      Text {
        text: "Empty-query list only — a real search still sorts by match quality"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.captionSize
      }
    }

    SettingRow {
      label: "Result limit"
      NSlider {
        Layout.preferredWidth: 160
        from: 5
        to: 60
        stepSize: 1
        value: Settings.data.launcher.resultLimit
        onMoved: value => Settings.data.launcher.resultLimit = Math.round(value)
      }
      Text {
        text: Settings.data.launcher.resultLimit
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }

    SettingRow {
      label: "Run-command prefix"

      Item {
        Layout.preferredWidth: 80
        height: 28

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: Color.surface
          strokeColor: prefixInput.activeFocus ? Color.primary : Color.outline
          strokeWidth: Tokens.borderModule
        }

        TextInput {
          id: prefixInput
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          verticalAlignment: Text.AlignVCenter
          text: Settings.data.launcher.execPrefix
          color: Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
          selectByMouse: true
          onEditingFinished: Settings.data.launcher.execPrefix = text
        }
      }

      Text {
        text: "Typing this first runs the rest as a shell command (sh -c) instead of searching apps. Empty disables it."
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.captionSize
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
      NSlider {
        Layout.preferredWidth: 160
        from: 10
        to: 200
        stepSize: 10
        value: Settings.data.clipboard.historyLimit
        onMoved: value => Settings.data.clipboard.historyLimit = Math.round(value)
      }
      Text {
        text: Settings.data.clipboard.historyLimit + " entries"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }

    Text {
      text: "Trims how many of cliphist's own entries are shown/kept in the popup — doesn't touch cliphist's own database or run a wipe."
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.captionSize
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }
  }
}
