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
      title: "Auto-dismiss"
    description: "Seconds before a non-resident popup dismisses itself, per urgency. Resident notifications (an app explicitly asks to stay) always ignore this."

    SettingRow {
      label: "Low urgency"
      NValueSlider {
        from: 1
        to: 30
        stepSize: 1
        value: Settings.data.notifications.lowUrgencyDurationSec
        sliderWidth: 160
        readoutText: Settings.data.notifications.lowUrgencyDurationSec + "s"
        onMoved: value => Settings.data.notifications.lowUrgencyDurationSec = value
      }
    }

    SettingRow {
      label: "Normal urgency"
      NValueSlider {
        from: 1
        to: 30
        stepSize: 1
        value: Settings.data.notifications.normalUrgencyDurationSec
        sliderWidth: 160
        readoutText: Settings.data.notifications.normalUrgencyDurationSec + "s"
        onMoved: value => Settings.data.notifications.normalUrgencyDurationSec = value
      }
    }

    SettingRow {
      label: "Critical urgency"
      NValueSlider {
        from: 1
        to: 60
        stepSize: 1
        value: Settings.data.notifications.criticalUrgencyDurationSec
        sliderWidth: 160
        readoutText: Settings.data.notifications.criticalUrgencyDurationSec + "s"
        onMoved: value => Settings.data.notifications.criticalUrgencyDurationSec = value
      }
    }

    SettingRow {
      label: "Respect app timeout"
      NToggle {
        checked: Settings.data.notifications.respectAppExpireTimeout
        onToggled: checked => Settings.data.notifications.respectAppExpireTimeout = checked
      }
      NText {
        text: "When an app requests its own expiry, honor it instead of the durations above."
        color: Color.labelText
        size: NText.Size.Caption
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
    }
  }

    Item {
      Layout.fillHeight: true
    }
  }
}
