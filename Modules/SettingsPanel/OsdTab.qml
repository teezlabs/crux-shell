import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// On-screen-display settings: crux's VolumeOsd.qml already runs reacting to
// live Pipewire state with no settings tab at all (position/duration were
// hardcoded). This is purely exposing what already exists.
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

  SettingsSection {
    title: "Volume OSD"
    description: "Shown briefly whenever the default sink's volume or mute state changes, from any source (hardware keys, another app, this shell)."

    SettingRow {
      label: "Enabled"
      NToggle {
        checked: Settings.data.osd.enabled
        onToggled: checked => Settings.data.osd.enabled = checked
      }
    }

    SettingRow {
      label: "Position"

      NSegmented {
        model: ["top", "center", "bottom"]
        currentKey: Settings.data.osd.position
        tileWidth: 70
        onSelected: key => Settings.data.osd.position = key
      }
    }

    SettingRow {
      label: "Duration"

      NValueSlider {
        from: 500
        to: 3000
        stepSize: 100
        value: Settings.data.osd.durationMs
        sliderWidth: 160
        readoutText: Settings.data.osd.durationMs + " ms"
        onMoved: value => Settings.data.osd.durationMs = value
      }
    }

    SettingRow {
      label: "Background opacity"
      NValueSlider {
        from: 0.4
        to: 1
        stepSize: 0.02
        value: Settings.data.osd.backgroundOpacity
        sliderWidth: 160
        readoutText: Math.round(Settings.data.osd.backgroundOpacity * 100) + "%"
        onMoved: value => Settings.data.osd.backgroundOpacity = value
      }
    }
  }

  SettingsSection {
    title: "Monitors"
    description: "Which screens show the OSD. None selected = all monitors."

    RowLayout {
      spacing: 6

      NMultiSelect {
        model: Quickshell.screens.map(s => s.name)
        selected: Settings.data.osd.monitors
        emptyMeansAll: true
        onChanged: selection => Settings.data.osd.monitors = selection
      }
    }
  }
  }
}
