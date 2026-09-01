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
      title: "Idle timeouts"
    description: (Idle.nativeIdleMonitorAvailable ? "ext-idle-notify-v1 available." : "Compositor idle protocol unavailable — timeouts below won't fire until it is.") + " Each stage is 0 = disabled; a stage only fires while enabled below."

    SettingRow {
      label: "Enabled"
      NToggle {
        checked: Settings.data.idle.enabled
        onToggled: checked => Settings.data.idle.enabled = checked
      }
    }

    SettingRow {
      enabled: Settings.data.idle.enabled
      label: "Screen off"
      NSlider {
        Layout.preferredWidth: 200
        from: 0
        to: 3600
        stepSize: 30
        value: Settings.data.idle.screenOffTimeoutSec
        onMoved: value => Settings.data.idle.screenOffTimeoutSec = value
      }
      Text {
        text: Settings.data.idle.screenOffTimeoutSec === 0 ? "off" : (Math.round(Settings.data.idle.screenOffTimeoutSec / 60) + " min")
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }

    SettingRow {
      enabled: Settings.data.idle.enabled
      label: "Lock"
      NSlider {
        Layout.preferredWidth: 200
        from: 0
        to: 3600
        stepSize: 30
        value: Settings.data.idle.lockTimeoutSec
        onMoved: value => Settings.data.idle.lockTimeoutSec = value
      }
      Text {
        text: Settings.data.idle.lockTimeoutSec === 0 ? "off" : (Math.round(Settings.data.idle.lockTimeoutSec / 60) + " min")
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }

    SettingRow {
      enabled: Settings.data.idle.enabled
      label: "Suspend"
      NSlider {
        Layout.preferredWidth: 200
        from: 0
        to: 7200
        stepSize: 60
        value: Settings.data.idle.suspendTimeoutSec
        onMoved: value => Settings.data.idle.suspendTimeoutSec = value
      }
      Text {
        text: Settings.data.idle.suspendTimeoutSec === 0 ? "off" : (Math.round(Settings.data.idle.suspendTimeoutSec / 60) + " min")
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }

    SettingRow {
      enabled: Settings.data.idle.enabled
      label: "Grace delay"
      NSlider {
        Layout.preferredWidth: 160
        from: 1
        to: 30
        stepSize: 1
        value: Settings.data.idle.fadeDurationSec
        onMoved: value => Settings.data.idle.fadeDurationSec = value
      }
      Text {
        text: Settings.data.idle.fadeDurationSec + "s"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }

    Text {
      text: "Grace delay: how long a stage waits after going idle before it actually fires — any activity in that window cancels it."
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.captionSize
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }

  SettingsSection {
    title: "Commands"
    description: "Leave blank to use the built-in default for each stage."
    enabled: Settings.data.idle.enabled

    GridLayout {
      columns: 2
      columnSpacing: 10
      rowSpacing: 10
      Layout.fillWidth: true

      Text {
        text: "Screen off"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
      CommandField {
        Layout.fillWidth: true
        placeholder: "hyprctl dispatch dpms off"
        value: Settings.data.idle.screenOffCommand
        onCommitted: v => Settings.data.idle.screenOffCommand = v
      }

      Text {
        text: "Resume screen off"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
      CommandField {
        Layout.fillWidth: true
        placeholder: "hyprctl dispatch dpms on"
        value: Settings.data.idle.resumeScreenOffCommand
        onCommitted: v => Settings.data.idle.resumeScreenOffCommand = v
      }

      Text {
        text: "Lock"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
      CommandField {
        Layout.fillWidth: true
        placeholder: "qs ipc -c crux call lockscreen lock"
        value: Settings.data.idle.lockCommand
        onCommitted: v => Settings.data.idle.lockCommand = v
      }

      Text {
        text: "Suspend"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
      CommandField {
        Layout.fillWidth: true
        placeholder: "systemctl suspend || loginctl suspend"
        value: Settings.data.idle.suspendCommand
        onCommitted: v => Settings.data.idle.suspendCommand = v
      }

      Text {
        text: "Resume suspend"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
      CommandField {
        Layout.fillWidth: true
        placeholder: "(none)"
        value: Settings.data.idle.resumeSuspendCommand
        onCommitted: v => Settings.data.idle.resumeSuspendCommand = v
      }
    }
  }

    Item {
      Layout.fillHeight: true
    }
  }

  component CommandField: Item {
    id: field
    property string value: ""
    property string placeholder: ""
    signal committed(string value)
    height: 26

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferIcon
      cutTopRight: true
      cutBottomLeft: true
      fillColor: Color.surface
      strokeColor: input.activeFocus ? Color.primary : Color.outline
      strokeWidth: Tokens.borderModule
    }

    TextInput {
      id: input
      anchors.fill: parent
      anchors.leftMargin: 8
      anchors.rightMargin: 8
      verticalAlignment: Text.AlignVCenter
      text: field.value
      color: text === "" ? Color.labelText : Color.surfaceText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.bodySmSize
      selectByMouse: true
      onEditingFinished: field.committed(text)

      Text {
        visible: input.text === "" && !input.activeFocus
        text: field.placeholder
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }
  }
}
