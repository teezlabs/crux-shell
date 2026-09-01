import QtQuick
import QtQuick.Layouts
import qs.Commons
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
    title: "Sampling"
    description: "How often CPU/RAM are polled, and the usage level that flags them as high."

    SettingRow {
      label: "Refresh"
      NSlider {
        Layout.preferredWidth: 200
        from: 500
        to: 10000
        stepSize: 500
        value: Settings.data.systemMonitor.refreshInterval
        onMoved: value => Settings.data.systemMonitor.refreshInterval = Math.round(value)
      }
      Text {
        text: (Settings.data.systemMonitor.refreshInterval / 1000).toFixed(1) + "s"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }

    SettingRow {
      label: "Warn at"
      NSlider {
        Layout.preferredWidth: 200
        from: 50
        to: 100
        stepSize: 1
        value: Settings.data.systemMonitor.warnThreshold
        onMoved: value => Settings.data.systemMonitor.warnThreshold = Math.round(value)
      }
      Text {
        text: Settings.data.systemMonitor.warnThreshold + "%"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }

    Text {
      text: "CPU or RAM at or above this turns the bar readout error-colored."
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.captionSize
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }
  }
}
