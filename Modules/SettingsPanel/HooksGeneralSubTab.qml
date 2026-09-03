import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// General subtab: the master enable switch + documentation of the
// placeholder scheme. Ported from noctalia's Hooks GeneralSubTab.
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
      title: "System hooks"
    description: "Master switch for every hook on the Hooks list. When off, no hook command runs even if one is set."

    SettingRow {
      label: "Enable hooks"
      NToggle {
        checked: Settings.data.hooks.enabled
        onToggled: value => Settings.data.hooks.enabled = value
      }
    }
  }

  SettingsSection {
    title: "Placeholders"
    description: "Hooks are shell commands run with `sh -lc`. Most support $1-style placeholders: wallpaper changed gets $1 path, $2 screen name, $3 theme (dark/light); color generation gets $1 theme; dark mode toggled gets $1 true/false; screen locked/unlocked get $1 lock/unlock; session action gets the action name appended as a plain argument."
  }

    Item {
      Layout.fillHeight: true
    }
  }
}
