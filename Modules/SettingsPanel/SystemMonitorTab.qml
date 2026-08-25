import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.SettingsPanel.Controls

ColumnLayout {
  id: root
  spacing: 20

  SettingsSection {
    title: "Sampling"

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
        color: Color.mOnSurfaceVariant
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Style.fontSizeS
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
        color: Color.mOnSurfaceVariant
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Style.fontSizeS
      }
    }

    Text {
      text: "CPU or RAM at or above this turns the bar readout error-colored."
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeXS
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
