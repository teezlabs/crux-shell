import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.ControlCenter
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Control Center configuration; live system state stays in the panel itself.
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

  SettingsSection {
    title: "Shortcut buttons"
    description: "The row of icon buttons under your name in the Control Center, left to right."

    CcIdListEditor {
      key: "shortcuts"
      registry: CcShortcutRegistry
      emptyText: "No shortcuts. The row is hidden."
    }

    SettingRow {
      label: "Screenshot command"
      description: "Run through sh -c, so flags work (e.g. \"rishot -c\")"

      NTextInput {
        Layout.preferredWidth: 220
        height: 28
        text: Settings.data.controlCenter.screenshotCommand
        onEditingFinished: Settings.data.controlCenter.screenshotCommand = text
      }
    }
  }

  SettingsSection {
    title: "Toggle tiles"
    description: "The tiles under the shortcut buttons in the Control Center, in reading order."

    CcIdListEditor {
      key: "toggles"
      registry: CcToggleRegistry
      emptyText: "No tiles. The grid is hidden."
    }
  }

  SettingsSection {
    title: "Weather"
    description: "The forecast card shown in the Control Center popup, when weather data is available."

    SettingRow {
      label: "Show weather card"
      NToggle {
        checked: Settings.data.controlCenter.showWeather
        onToggled: checked => Settings.data.controlCenter.showWeather = checked
      }
    }

    SettingRow {
      label: "Temperature unit"

      NSegmented {
        model: [{
            "key": "fahrenheit",
            "label": "°F"
          }, {
            "key": "celsius",
            "label": "°C"
          }]
        currentKey: Settings.data.controlCenter.tempUnit
        tileWidth: 56
        uppercase: false
        onSelected: key => Settings.data.controlCenter.tempUnit = key
      }
    }
  }

  SettingsSection {
    title: "Homelab"
    description: "Hosts the Control Center pings while it's open. The card is hidden while this list is empty."

    SettingRow {
      label: "Hosts"
      description: "name=address, separated by commas"

      NTextInput {
        Layout.fillWidth: true
        height: 28
        text: Settings.data.homelab.hosts.join(", ")
        placeholderText: "nas=10.0.0.5, pi=raspberrypi.lan"
        onEditingFinished: Settings.data.homelab.hosts = text.split(",").map(h => h.trim()).filter(h => h.indexOf("=") > 0)
      }
    }

    SettingRow {
      label: "Dashboard"
      description: "Opened by DASHBOARD on the card"

      NTextInput {
        Layout.fillWidth: true
        height: 28
        text: Settings.data.homelab.dashboardUrl
        placeholderText: "https://dashboard.lan"
        onEditingFinished: Settings.data.homelab.dashboardUrl = text.trim()
      }
    }
  }
  }
}
