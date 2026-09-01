import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls

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
      title: "Clock"
      description: "The time/date format shown on the lock screen."

    SettingRow {
      label: "Time format"

      Item {
        Layout.preferredWidth: 160
        height: 28

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: Color.surface
          strokeColor: clockInput.activeFocus ? Color.primary : Color.outline
          strokeWidth: Tokens.borderModule
        }

        TextInput {
          id: clockInput
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          verticalAlignment: Text.AlignVCenter
          text: Settings.data.lockScreen.clockFormat
          color: Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
          selectByMouse: true
          onEditingFinished: Settings.data.lockScreen.clockFormat = text
        }
      }

      Text {
        text: "Qt date/time format, e.g. HH:mm or h:mm AP"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.captionSize
      }
    }

    SettingRow {
      label: "Date format"

      Item {
        Layout.preferredWidth: 220
        height: 28

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: Color.surface
          strokeColor: dateInput.activeFocus ? Color.primary : Color.outline
          strokeWidth: Tokens.borderModule
        }

        TextInput {
          id: dateInput
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          verticalAlignment: Text.AlignVCenter
          text: Settings.data.lockScreen.dateFormat
          color: Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
          selectByMouse: true
          onEditingFinished: Settings.data.lockScreen.dateFormat = text
        }
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
      Text {
        text: "Off = mirror the live desktop wallpaper"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.captionSize
      }
    }

    SettingRow {
      visible: Settings.data.lockScreen.useCustomWallpaper
      label: "Image path"

      Item {
        Layout.fillWidth: true
        height: 28

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: Color.surface
          strokeColor: wpInput.activeFocus ? Color.primary : Color.outline
          strokeWidth: Tokens.borderModule
        }

        TextInput {
          id: wpInput
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          verticalAlignment: Text.AlignVCenter
          text: Settings.data.lockScreen.customWallpaperPath
          color: Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
          selectByMouse: true
          onEditingFinished: Settings.data.lockScreen.customWallpaperPath = text
        }
      }
    }

    SettingRow {
      label: "Blur amount"
      NSlider {
        Layout.preferredWidth: 160
        from: 0
        to: 1
        stepSize: 0.05
        value: Settings.data.lockScreen.blurAmount
        onMoved: value => Settings.data.lockScreen.blurAmount = value
      }
      Text {
        text: Math.round(Settings.data.lockScreen.blurAmount * 100) + "%"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }

    SettingRow {
      label: "Dim amount"
      NSlider {
        Layout.preferredWidth: 160
        from: 0
        to: 1
        stepSize: 0.05
        value: Settings.data.lockScreen.dimAmount
        onMoved: value => Settings.data.lockScreen.dimAmount = value
      }
      Text {
        text: Math.round(Settings.data.lockScreen.dimAmount * 100) + "%"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
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
  }

    Item {
      Layout.fillHeight: true
    }
  }
}
