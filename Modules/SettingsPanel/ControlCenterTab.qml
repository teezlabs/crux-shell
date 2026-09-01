import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls

// Control Center settings: ControlCenter.qml (bar icon) + ControlCenterWindow.qml
// (the popup itself) were built with most rows tied to live system state
// (Wifi/Bluetooth/audio/brightness aren't user preferences, they're just
// read live) — this covers the handful of rows that actually were
// hardcoded constants rather than real data.
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

            Text {
              anchors.centerIn: parent
              text: unitTile.modelData.label
              color: unitTile.active ? Color.primaryContainerText : Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
              font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
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

      Text {
        text: Settings.data.controlCenter.statsRefreshInterval + " ms"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }
  }

  SettingsSection {
    title: "Actions"
    description: "The command run by the CAPTURE action tile."

    SettingRow {
      label: "Screenshot command"

      Item {
        Layout.preferredWidth: 220
        height: 28

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: Color.surface
          strokeColor: captureInput.activeFocus ? Color.primary : Color.outline
          strokeWidth: Tokens.borderModule
        }

        TextInput {
          id: captureInput
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          verticalAlignment: Text.AlignVCenter
          text: Settings.data.controlCenter.screenshotCommand
          color: Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
          selectByMouse: true
          onEditingFinished: Settings.data.controlCenter.screenshotCommand = text
        }
      }
    }

    Text {
      text: "Run through sh -c, so flags/arguments work (e.g. \"rishot -c\")."
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.captionSize
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }
  }
}
