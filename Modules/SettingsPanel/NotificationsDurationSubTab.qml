import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

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
      title: "Auto-dismiss"
    description: "Seconds before a non-resident popup dismisses itself, per urgency. Resident notifications (an app explicitly asks to stay) always ignore this."

    SettingRow {
      label: "Low urgency"
      NSlider {
        Layout.preferredWidth: 160
        from: 1
        to: 30
        stepSize: 1
        value: Settings.data.notifications.lowUrgencyDurationSec
        onMoved: value => Settings.data.notifications.lowUrgencyDurationSec = value
      }
      NText {
        text: Settings.data.notifications.lowUrgencyDurationSec + "s"
        color: Color.labelText
        size: NText.Size.BodySm
      }
    }

    SettingRow {
      label: "Normal urgency"
      NSlider {
        Layout.preferredWidth: 160
        from: 1
        to: 30
        stepSize: 1
        value: Settings.data.notifications.normalUrgencyDurationSec
        onMoved: value => Settings.data.notifications.normalUrgencyDurationSec = value
      }
      NText {
        text: Settings.data.notifications.normalUrgencyDurationSec + "s"
        color: Color.labelText
        size: NText.Size.BodySm
      }
    }

    SettingRow {
      label: "Critical urgency"
      NSlider {
        Layout.preferredWidth: 160
        from: 1
        to: 60
        stepSize: 1
        value: Settings.data.notifications.criticalUrgencyDurationSec
        onMoved: value => Settings.data.notifications.criticalUrgencyDurationSec = value
      }
      NText {
        text: Settings.data.notifications.criticalUrgencyDurationSec + "s"
        color: Color.labelText
        size: NText.Size.BodySm
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
