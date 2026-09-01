import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.SettingsPanel.Controls

// Night Light (wlsunset) settings: night/day color temperature and a
// manual sunset/sunrise schedule — ported from noctalia's
// Modules/Panels/Settings/Tabs/Display/NightLightSubTab.qml, minus the
// geolocation-driven auto-schedule mode (crux has no LocationService yet).
Flickable {
  id: root
  clip: true
  contentWidth: width
  contentHeight: col.implicitHeight

  function minutesToLabel(min) {
    var h = Math.floor(min / 60);
    var m = min % 60;
    return (h < 10 ? "0" : "") + h + ":" + (m < 10 ? "0" : "") + m;
  }

  function timeToMinutes(str) {
    var parts = String(str || "00:00").split(":").map(Number);
    return (parts[0] || 0) * 60 + (parts[1] || 0);
  }

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

    SettingsSection {
    title: "Night Light"
    description: "Blue-light filter via wlsunset. Manual schedule only — no geolocation-based sunrise/sunset in crux yet."

    SettingRow {
      label: "Enabled"
      NToggle {
        checked: Settings.data.nightLight.enabled
        onToggled: checked => {
          Settings.data.nightLight.enabled = checked;
          if (!checked)
            Settings.data.nightLight.forced = false;
        }
      }
    }

    SettingRow {
      label: "Force now"
      NToggle {
        enabled: Settings.data.nightLight.enabled
        checked: Settings.data.nightLight.forced
        onToggled: checked => Settings.data.nightLight.forced = checked
      }
    }

    SettingRow {
      label: "Night temp"
      NSlider {
        id: nightSlider
        Layout.preferredWidth: 200
        from: 1000
        to: 6500
        stepSize: 100
        value: Settings.data.nightLight.nightTemp
        onMoved: value => {
          var maxNight = Settings.data.nightLight.dayTemp - 500;
          Settings.data.nightLight.nightTemp = Math.round(Math.min(maxNight, Math.max(1000, value)));
        }
      }
      Text {
        text: Settings.data.nightLight.nightTemp + "K"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }

    SettingRow {
      label: "Day temp"
      NSlider {
        id: daySlider
        Layout.preferredWidth: 200
        from: 1000
        to: 6500
        stepSize: 100
        value: Settings.data.nightLight.dayTemp
        onMoved: value => {
          var minDay = Settings.data.nightLight.nightTemp + 500;
          Settings.data.nightLight.dayTemp = Math.round(Math.max(minDay, Math.min(6500, value)));
        }
      }
      Text {
        text: Settings.data.nightLight.dayTemp + "K"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }
  }

  SettingsSection {
    title: "Manual schedule"
    description: "Ignored while Night Light is forced on."

    SettingRow {
      label: "Sunset"
      NSlider {
        Layout.preferredWidth: 200
        from: 0
        to: 1425
        stepSize: 15
        value: root.timeToMinutes(Settings.data.nightLight.manualSunset)
        onMoved: value => Settings.data.nightLight.manualSunset = root.minutesToLabel(Math.round(value))
      }
      Text {
        text: Settings.data.nightLight.manualSunset
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }

    SettingRow {
      label: "Sunrise"
      NSlider {
        Layout.preferredWidth: 200
        from: 0
        to: 1425
        stepSize: 15
        value: root.timeToMinutes(Settings.data.nightLight.manualSunrise)
        onMoved: value => Settings.data.nightLight.manualSunrise = root.minutesToLabel(Math.round(value))
      }
      Text {
        text: Settings.data.nightLight.manualSunrise
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }
  }

    Item {
      Layout.fillHeight: true
    }
  }
}
