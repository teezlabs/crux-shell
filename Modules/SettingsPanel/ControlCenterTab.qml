import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Control Center settings: only the rows that are real hardcoded
// constants, not live system state (Wifi/Bluetooth/audio/brightness).
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

      RowLayout {
        spacing: 6

        Repeater {
          model: [{
              "id": "fahrenheit",
              "label": "°F"
            }, {
              "id": "celsius",
              "label": "°C"
            }]
          delegate: Item {
            id: unitTile
            required property var modelData
            readonly property bool active: Settings.data.controlCenter.tempUnit === modelData.id
            Layout.preferredWidth: 56
            height: 28

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: unitTile.active ? Color.primaryContainer : (unitHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer)
              strokeColor: unitTile.active ? Color.primary : Color.outline
              strokeWidth: Tokens.borderModule
            }

            NText {
              tracking: true
              anchors.centerIn: parent
              text: unitTile.modelData.label
              color: unitTile.active ? Color.primaryContainerText : Color.surfaceText
              size: NText.Size.LabelXs
            }

            HoverHandler {
              id: unitHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: Settings.data.controlCenter.tempUnit = unitTile.modelData.id
            }
          }
        }
      }
    }
  }

  SettingsSection {
    title: "System stats"
    description: "How often the CPU/MEM/TEMP/DISK gauges refresh while the popup is open."

    SettingRow {
      label: "Refresh interval"

      NSlider {
        Layout.preferredWidth: 160
        from: 500
        to: 5000
        stepSize: 100
        value: Settings.data.controlCenter.statsRefreshInterval
        onMoved: value => Settings.data.controlCenter.statsRefreshInterval = Math.round(value)
      }

      NText {
        text: Settings.data.controlCenter.statsRefreshInterval + " ms"
        color: Color.labelText
        size: NText.Size.BodySm
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
