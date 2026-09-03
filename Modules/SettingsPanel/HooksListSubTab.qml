import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// The hook list — one HookRow per Settings.data.hooks.* field, each with an
// EDIT button opening the shared HookEditPopup. TEST in the popup runs the
// currently-edited command with sample placeholder values (same semantics
// as noctalia's HooksListSubTab test handlers).
NScrollView {
  id: root

  property var targetScreen: null

  enabled: Settings.data.hooks.enabled
  clip: true
  contentWidth: width
  contentHeight: col.implicitHeight

  HookEditPopup {
    id: editPopup
    targetScreen: root.targetScreen
  }

  function _openEdit(label, description, placeholder, value, saveCb, testCb) {
    editPopup.openFor(label, description, placeholder, value, saveCb, testCb);
  }

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

    SettingsSection {
      title: "System hooks"
      description: "Each hook is a shell command run with `sh -lc`. Commands are stored in settings.json under hooks.*."

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 12

      HookRow {
        label: "On shell start"
        description: "Runs once when crux finishes booting. No placeholders."
        value: Settings.data.hooks.startup
        onEditClicked: root._openEdit(label, description, "e.g. notify-send 'crux started'", value, function (v) {
          Settings.data.hooks.startup = v;
        }, function (val) {
          if (val)
            Quickshell.execDetached(["sh", "-lc", val]);
        })
      }

      HookRow {
        label: "Wallpaper changed"
        description: "$1 wallpaper path, $2 screen name, $3 theme (dark/light)."
        value: Settings.data.hooks.wallpaperChange
        onEditClicked: root._openEdit(label, description, "e.g. $HOME/bin/wallpaper-hook.sh $1 $2 $3", value, function (v) {
          Settings.data.hooks.wallpaperChange = v;
        }, function (val) {
          if (val)
            Quickshell.execDetached(["sh", "-lc", val.replace(/\$1/g, "test_wallpaper_path").replace(/\$2/g, "test_screen").replace(/\$3/g, "dark")]);
        })
      }

      HookRow {
        label: "Color generation"
        description: "Runs after matugen regenerates colors for a wallpaper. $1 theme (dark/light)."
        value: Settings.data.hooks.colorGeneration
        onEditClicked: root._openEdit(label, description, "e.g. notify-send 'colors generated' $1", value, function (v) {
          Settings.data.hooks.colorGeneration = v;
        }, function (val) {
          if (val)
            Quickshell.execDetached(["sh", "-lc", val.replace(/\$1/g, "dark")]);
        })
      }

      HookRow {
        label: "Dark mode toggled"
        description: "Runs when dark/light mode switches. $1 true/false for the new mode."
        value: Settings.data.hooks.darkModeChange
        onEditClicked: root._openEdit(label, description, "e.g. notify-send 'dark mode' $1", value, function (v) {
          Settings.data.hooks.darkModeChange = v;
        }, function (val) {
          if (val)
            Quickshell.execDetached(["sh", "-lc", val.replace(/\$1/g, "true")]);
        })
      }

      HookRow {
        label: "Screen locked"
        description: "Runs when the lock screen engages. $1 = lock."
        value: Settings.data.hooks.screenLock
        onEditClicked: root._openEdit(label, description, "e.g. playerctl pause", value, function (v) {
          Settings.data.hooks.screenLock = v;
        }, function (val) {
          if (val)
            Quickshell.execDetached(["sh", "-lc", val]);
        })
      }

      HookRow {
        label: "Screen unlocked"
        description: "Runs when the lock screen releases. $1 = unlock."
        value: Settings.data.hooks.screenUnlock
        onEditClicked: root._openEdit(label, description, "e.g. notify-send 'unlocked'", value, function (v) {
          Settings.data.hooks.screenUnlock = v;
        }, function (val) {
          if (val)
            Quickshell.execDetached(["sh", "-lc", val]);
        })
      }

      HookRow {
        label: "Session action"
        description: "Runs before a power-menu action — the action name (lock, suspend, logout, reboot, shutdown) is appended as an argument, and the action waits for this hook to exit."
        value: Settings.data.hooks.session
        onEditClicked: root._openEdit(label, description, "e.g. $HOME/bin/pre-action.sh", value, function (v) {
          Settings.data.hooks.session = v;
        }, function (val) {
          if (val)
            Quickshell.execDetached(["sh", "-lc", val + " test"]);
        })
      }
      }
    }

    Item {
      Layout.fillHeight: true
    }
  }
}
