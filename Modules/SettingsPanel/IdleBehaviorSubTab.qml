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
      NValueSlider {
        from: 0
        to: 3600
        stepSize: 30
        value: Settings.data.idle.screenOffTimeoutSec
        sliderWidth: 200
        readoutText: Settings.data.idle.screenOffTimeoutSec === 0 ? "off" : (Math.round(Settings.data.idle.screenOffTimeoutSec / 60) + " min")
        onMoved: value => Settings.data.idle.screenOffTimeoutSec = value
      }
    }

    SettingRow {
      enabled: Settings.data.idle.enabled
      label: "Lock"
      NValueSlider {
        from: 0
        to: 3600
        stepSize: 30
        value: Settings.data.idle.lockTimeoutSec
        sliderWidth: 200
        readoutText: Settings.data.idle.lockTimeoutSec === 0 ? "off" : (Math.round(Settings.data.idle.lockTimeoutSec / 60) + " min")
        onMoved: value => Settings.data.idle.lockTimeoutSec = value
      }
    }

    SettingRow {
      enabled: Settings.data.idle.enabled
      label: "Suspend"
      NValueSlider {
        from: 0
        to: 7200
        stepSize: 60
        value: Settings.data.idle.suspendTimeoutSec
        sliderWidth: 200
        readoutText: Settings.data.idle.suspendTimeoutSec === 0 ? "off" : (Math.round(Settings.data.idle.suspendTimeoutSec / 60) + " min")
        onMoved: value => Settings.data.idle.suspendTimeoutSec = value
      }
    }

    SettingRow {
      enabled: Settings.data.idle.enabled
      label: "Grace delay"
      NValueSlider {
        from: 1
        to: 30
        stepSize: 1
        value: Settings.data.idle.fadeDurationSec
        sliderWidth: 160
        readoutText: Settings.data.idle.fadeDurationSec + "s"
        onMoved: value => Settings.data.idle.fadeDurationSec = value
      }
    }

    NText {
      text: "Grace delay: how long a stage waits after going idle before it actually fires — any activity in that window cancels it."
      color: Color.labelText
      size: NText.Size.Caption
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

      NText {
        text: "Screen off"
        color: Color.labelText
        size: NText.Size.BodySm
      }
      CommandField {
        Layout.fillWidth: true
        placeholder: "hyprctl dispatch dpms off"
        value: Settings.data.idle.screenOffCommand
        onCommitted: v => Settings.data.idle.screenOffCommand = v
      }

      NText {
        text: "Resume screen off"
        color: Color.labelText
        size: NText.Size.BodySm
      }
      CommandField {
        Layout.fillWidth: true
        placeholder: "hyprctl dispatch dpms on"
        value: Settings.data.idle.resumeScreenOffCommand
        onCommitted: v => Settings.data.idle.resumeScreenOffCommand = v
      }

      NText {
        text: "Lock"
        color: Color.labelText
        size: NText.Size.BodySm
      }
      CommandField {
        Layout.fillWidth: true
        placeholder: "qs ipc -c crux call lockscreen lock"
        value: Settings.data.idle.lockCommand
        onCommitted: v => Settings.data.idle.lockCommand = v
      }

      NText {
        text: "Suspend"
        color: Color.labelText
        size: NText.Size.BodySm
      }
      CommandField {
        Layout.fillWidth: true
        placeholder: "systemctl suspend || loginctl suspend"
        value: Settings.data.idle.suspendCommand
        onCommitted: v => Settings.data.idle.suspendCommand = v
      }

      NText {
        text: "Resume suspend"
        color: Color.labelText
        size: NText.Size.BodySm
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

      NText {
        visible: input.text === "" && !input.activeFocus
        text: field.placeholder
        color: Color.labelText
        size: NText.Size.BodySm
      }
    }
  }
}
