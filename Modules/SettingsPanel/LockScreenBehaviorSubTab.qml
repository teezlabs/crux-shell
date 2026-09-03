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
      title: "Grace period"
    description: "Within this many seconds of locking, pressing Enter on an empty password field unlocks immediately — no re-auth. 0 disables this (always require a real password)."

    SettingRow {
      label: "Grace period"
      NSlider {
        Layout.preferredWidth: 160
        from: 0
        to: 30
        stepSize: 1
        value: Settings.data.lockScreen.gracePeriodSec
        onMoved: value => Settings.data.lockScreen.gracePeriodSec = value
      }
      NText {
        text: Settings.data.lockScreen.gracePeriodSec === 0 ? "off" : (Settings.data.lockScreen.gracePeriodSec + "s")
        color: Color.labelText
        size: NText.Size.BodySm
      }
    }
  }

  SettingsSection {
    title: "Failed attempts"
    description: "Lock out the password field for a cooldown period after too many wrong attempts in a row. 0 = unlimited attempts, never locks out."

    SettingRow {
      label: "Max attempts"
      NSlider {
        Layout.preferredWidth: 160
        from: 0
        to: 10
        stepSize: 1
        value: Settings.data.lockScreen.maxFailedAttempts
        onMoved: value => Settings.data.lockScreen.maxFailedAttempts = value
      }
      NText {
        text: Settings.data.lockScreen.maxFailedAttempts === 0 ? "unlimited" : Settings.data.lockScreen.maxFailedAttempts
        color: Color.labelText
        size: NText.Size.BodySm
      }
    }

    SettingRow {
      visible: Settings.data.lockScreen.maxFailedAttempts > 0
      label: "Lockout duration"
      NSlider {
        Layout.preferredWidth: 160
        from: 5
        to: 300
        stepSize: 5
        value: Settings.data.lockScreen.lockoutDurationSec
        onMoved: value => Settings.data.lockScreen.lockoutDurationSec = value
      }
      NText {
        text: Settings.data.lockScreen.lockoutDurationSec + "s"
        color: Color.labelText
        size: NText.Size.BodySm
      }
    }
  }

    Item {
      Layout.fillHeight: true
    }
  }
}
