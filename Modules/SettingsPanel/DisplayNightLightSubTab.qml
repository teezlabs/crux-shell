import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Night Light (wlsunset) settings: night/day color temperature, a real
// geolocation-driven auto-schedule (reusing Commons/Weather.qml's own
// IP-geolocated lat/lon — see NightLight.qml), and a manual sunset/sunrise
// fallback for when that's off or hasn't resolved yet.
NScrollView {
  id: root
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
    description: "Blue-light filter via wlsunset."

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
      label: "Use my location"
      NToggle {
        checked: Settings.data.nightLight.useLocation
        onToggled: checked => Settings.data.nightLight.useLocation = checked
      }
      NText {
        text: Weather.hasLocation ? "Real sunrise/sunset for " + Weather.cityName : "Resolving location…"
        color: Color.labelText
        size: NText.Size.Caption
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
      NText {
        text: Settings.data.nightLight.nightTemp + "K"
        color: Color.labelText
        size: NText.Size.BodySm
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
      NText {
        text: Settings.data.nightLight.dayTemp + "K"
        color: Color.labelText
        size: NText.Size.BodySm
      }
    }
  }

  SettingsSection {
    title: "Manual schedule"
    description: "Ignored while Night Light is forced on, or while \"Use my location\" is on and resolved."

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 12
      enabled: !Settings.data.nightLight.useLocation || !Weather.hasLocation
      opacity: enabled ? 1 : 0.4

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
        NText {
          text: Settings.data.nightLight.manualSunset
          color: Color.labelText
          size: NText.Size.BodySm
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
        NText {
          text: Settings.data.nightLight.manualSunrise
          color: Color.labelText
          size: NText.Size.BodySm
        }
      }
    }
  }

    Item {
      Layout.fillHeight: true
    }
  }
}
