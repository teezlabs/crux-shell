import QtQuick
import QtQuick.Layouts
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
      title: "Clock"
      description: "The time/date format shown on the lock screen."

    SettingRow {
      label: "Time format"

      NTextInput {
        id: clockInput
        Layout.preferredWidth: 160
        height: 28
        text: Settings.data.lockScreen.clockFormat
        onEditingFinished: Settings.data.lockScreen.clockFormat = text
      }

      NText {
        text: "Qt date/time format, e.g. HH:mm or h:mm AP"
        color: Color.labelText
        size: NText.Size.Caption
      }
    }

    SettingRow {
      label: "Date format"

      NTextInput {
        id: dateInput
        Layout.preferredWidth: 220
        height: 28
        text: Settings.data.lockScreen.dateFormat
        onEditingFinished: Settings.data.lockScreen.dateFormat = text
      }
    }
  }

  SettingsSection {
    title: "Wallpaper"
    description: "The background image and its blur/dim, behind the unlock form."

    SettingRow {
      label: "Custom wallpaper"
      NToggle {
        checked: Settings.data.lockScreen.useCustomWallpaper
        onToggled: checked => Settings.data.lockScreen.useCustomWallpaper = checked
      }
      NText {
        text: "Off = mirror the live desktop wallpaper"
        color: Color.labelText
        size: NText.Size.Caption
      }
    }

    SettingRow {
      visible: Settings.data.lockScreen.useCustomWallpaper
      label: "Image path"

      NTextInput {
        id: wpInput
        Layout.fillWidth: true
        height: 28
        text: Settings.data.lockScreen.customWallpaperPath
        onEditingFinished: Settings.data.lockScreen.customWallpaperPath = text
      }
    }

    SettingRow {
      label: "Blur amount"
      NValueSlider {
        from: 0
        to: 1
        stepSize: 0.05
        value: Settings.data.lockScreen.blurAmount
        sliderWidth: 160
        readoutText: Math.round(Settings.data.lockScreen.blurAmount * 100) + "%"
        onMoved: value => Settings.data.lockScreen.blurAmount = value
      }
    }

    SettingRow {
      label: "Dim amount"
      NValueSlider {
        from: 0
        to: 1
        stepSize: 0.05
        value: Settings.data.lockScreen.dimAmount
        sliderWidth: 160
        readoutText: Math.round(Settings.data.lockScreen.dimAmount * 100) + "%"
        onMoved: value => Settings.data.lockScreen.dimAmount = value
      }
    }
  }

  SettingsSection {
    title: "Status row"
    description: "Shown top-right of the unlock form."

    SettingRow {
      label: "Network"
      NToggle {
        checked: Settings.data.lockScreen.showNetwork
        onToggled: checked => Settings.data.lockScreen.showNetwork = checked
      }
    }
    SettingRow {
      label: "Battery"
      NToggle {
        checked: Settings.data.lockScreen.showBattery
        onToggled: checked => Settings.data.lockScreen.showBattery = checked
      }
    }
    SettingRow {
      label: "Volume"
      NToggle {
        checked: Settings.data.lockScreen.showVolume
        onToggled: checked => Settings.data.lockScreen.showVolume = checked
      }
    }
    SettingRow {
      label: "Notifications"
      NToggle {
        checked: Settings.data.lockScreen.showNotifications
        onToggled: checked => Settings.data.lockScreen.showNotifications = checked
      }
    }
    SettingRow {
      label: "Now playing"
      NToggle {
        checked: Settings.data.lockScreen.showMediaControls
        onToggled: checked => Settings.data.lockScreen.showMediaControls = checked
      }
      NText {
        text: "Read-only track info, no playback buttons on the lock screen"
        color: Color.labelText
        size: NText.Size.Caption
      }
    }
  }

    Item {
      Layout.fillHeight: true
    }
  }
}
