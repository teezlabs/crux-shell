import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Control Center settings: only the rows that are real hardcoded
// constants, not live system state (Wifi/Bluetooth/audio/brightness).
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

  SettingsSection {
    title: "Quick toggles"
    description: "Buttons in the Control Center's top row, in order."

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      Repeater {
        model: Settings.data.controlCenter.toggles

        delegate: RowLayout {
          id: row
          required property string modelData
          required property int index
          Layout.fillWidth: true
          spacing: 6

          NText {
            text: row.modelData
            color: Color.surfaceText
            size: NText.Size.BodySm
            Layout.fillWidth: true
          }

          NButton {
            text: "\u2191"
            horizontalPadding: 8
            enabled: row.index > 0
            onClicked: Settings.moveCcToggle(row.index, -1)
          }
          NButton {
            text: "\u2193"
            horizontalPadding: 8
            enabled: row.index < Settings.data.controlCenter.toggles.length - 1
            onClicked: Settings.moveCcToggle(row.index, 1)
          }
          NButton {
            text: "Remove"
            variant: "destructive"
            onClicked: Settings.removeCcToggle(row.index)
          }
        }
      }

      NText {
        visible: Settings.data.controlCenter.toggles.length === 0
        text: "No toggles — the row is hidden."
        color: Color.labelText
        size: NText.Size.Caption
      }

      NText {
        tracking: true
        text: "ADD"
        color: Color.labelText
        size: NText.Size.LabelXs
        Layout.topMargin: 4
      }

      Flow {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
          model: CcToggleRegistry.ids

          delegate: NButton {
            required property string modelData
            text: modelData
            textSize: NText.Size.LabelXs
            horizontalPadding: 8
            implicitHeight: 22
            enabled: Settings.data.controlCenter.toggles.indexOf(modelData) === -1
            onClicked: Settings.addCcToggle(modelData)
          }
        }
      }
    }
  }

  SettingsSection {
    title: "Weather"
    description: "The forecast card shown in the Control Center popup, when weather data is available."

    SettingRow {
      label: "Show weather card"
      NToggle {
        checked: Settings.data.controlCenter.showWeather
        onToggled: checked => Settings.data.controlCenter.showWeather = checked
      }
    }

    SettingRow {
      label: "Temperature unit"

      NSegmented {
        model: [{
            "key": "fahrenheit",
            "label": "°F"
          }, {
            "key": "celsius",
            "label": "°C"
          }]
        currentKey: Settings.data.controlCenter.tempUnit
        tileWidth: 56
        uppercase: false
        onSelected: key => Settings.data.controlCenter.tempUnit = key
      }
    }
  }

  SettingsSection {
    title: "System stats"
    description: "How often the CPU/MEM/TEMP/DISK gauges refresh while the popup is open."

    SettingRow {
      label: "Refresh interval"

      NValueSlider {
        from: 500
        to: 5000
        stepSize: 100
        value: Settings.data.controlCenter.statsRefreshInterval
        sliderWidth: 160
        readoutText: Settings.data.controlCenter.statsRefreshInterval + " ms"
        onMoved: value => Settings.data.controlCenter.statsRefreshInterval = Math.round(value)
      }
    }
  }

  SettingsSection {
    title: "Actions"
    description: "The command run by the CAPTURE action tile."

    SettingRow {
      label: "Screenshot command"

      NTextInput {
        id: captureInput
        Layout.preferredWidth: 220
        height: 28
        text: Settings.data.controlCenter.screenshotCommand
        onEditingFinished: Settings.data.controlCenter.screenshotCommand = text
      }
    }

    NText {
      text: "Run through sh -c, so flags/arguments work (e.g. \"rishot -c\")."
      color: Color.labelText
      size: NText.Size.Caption
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }
  }
}
