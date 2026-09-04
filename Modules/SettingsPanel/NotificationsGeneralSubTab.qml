import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
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
      title: "Popups"
      description: "Turn popups on or off, mute them temporarily, and cap how many stack at once."

    SettingRow {
      label: "Enabled"
      NToggle {
        checked: Settings.data.notifications.enabled
        onToggled: checked => Settings.data.notifications.enabled = checked
      }
      NText {
        text: "Off disables the live popup stack only — history still logs every real notification."
        color: Color.labelText
        size: NText.Size.Caption
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
    }

    SettingRow {
      label: "Do not disturb"
      NToggle {
        checked: Settings.data.notifications.doNotDisturb
        onToggled: checked => Settings.data.notifications.doNotDisturb = checked
      }
      NText {
        text: "Temporary — suppresses popups without turning them off entirely."
        color: Color.labelText
        size: NText.Size.Caption
      }
    }

    SettingRow {
      label: "Max visible"
      NValueSlider {
        from: 1
        to: 8
        stepSize: 1
        value: Settings.data.notifications.maxVisible
        sliderWidth: 140
        readoutText: Settings.data.notifications.maxVisible + " at once"
        onMoved: value => Settings.data.notifications.maxVisible = value
      }
    }
  }

  SettingsSection {
    title: "Position"
    description: "Which corner of the screen new popups appear in."

    NSegmented {
      model: [
        {
          "key": "top_left",
          "label": "Top left"
        },
        {
          "key": "top_right",
          "label": "Top right"
        },
        {
          "key": "bottom_left",
          "label": "Bottom left"
        },
        {
          "key": "bottom_right",
          "label": "Bottom right"
        }
      ]
      currentKey: Settings.data.notifications.position
      tileWidth: 96
      onSelected: key => Settings.data.notifications.position = key
    }
  }

    SettingsSection {
      title: "Card"
      description: "Background opacity of the popup card itself."

      SettingRow {
        label: "Background opacity"
        NValueSlider {
          from: 0.4
          to: 1
          stepSize: 0.02
          value: Settings.data.notifications.backgroundOpacity
          sliderWidth: 140
          readoutText: Math.round(Settings.data.notifications.backgroundOpacity * 100) + "%"
          onMoved: value => Settings.data.notifications.backgroundOpacity = value
        }
      }
    }

    SettingsSection {
      title: "Monitors"
      description: "Which screens show popups. None selected = all monitors."

      RowLayout {
        spacing: 6

        NMultiSelect {
          model: Quickshell.screens.map(s => s.name)
          selected: Settings.data.notifications.monitors
          emptyMeansAll: true
          onChanged: selection => Settings.data.notifications.monitors = selection
        }
      }
    }

    Item {
      Layout.fillHeight: true
    }
  }
}
