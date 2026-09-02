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

  }

  SettingsSection {
    title: "Thresholds"
    description: "Per-metric warning/critical usage levels — CPU, RAM, disk, and temperature don't all warrant the same cutoff."

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 4

      Text {
        text: "CPU"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
      }
      SettingRow {
        label: "Warning"
        NSlider {
          Layout.preferredWidth: 160
          from: 30
          to: 99
          stepSize: 1
          value: Settings.data.systemMonitor.cpuWarningThreshold
          onMoved: value => Settings.data.systemMonitor.cpuWarningThreshold = Math.round(value)
        }
        Text {
          text: Settings.data.systemMonitor.cpuWarningThreshold + "%"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
        }
      }
      SettingRow {
        label: "Critical"
        NSlider {
          Layout.preferredWidth: 160
          from: 30
          to: 100
          stepSize: 1
          value: Settings.data.systemMonitor.cpuCriticalThreshold
          onMoved: value => Settings.data.systemMonitor.cpuCriticalThreshold = Math.round(value)
        }
        Text {
          text: Settings.data.systemMonitor.cpuCriticalThreshold + "%"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.topMargin: 10
      spacing: 4

      Text {
        text: "RAM"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
      }
      SettingRow {
        label: "Warning"
        NSlider {
          Layout.preferredWidth: 160
          from: 30
          to: 99
          stepSize: 1
          value: Settings.data.systemMonitor.memWarningThreshold
          onMoved: value => Settings.data.systemMonitor.memWarningThreshold = Math.round(value)
        }
        Text {
          text: Settings.data.systemMonitor.memWarningThreshold + "%"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
        }
      }
      SettingRow {
        label: "Critical"
        NSlider {
          Layout.preferredWidth: 160
          from: 30
          to: 100
          stepSize: 1
          value: Settings.data.systemMonitor.memCriticalThreshold
          onMoved: value => Settings.data.systemMonitor.memCriticalThreshold = Math.round(value)
        }
        Text {
          text: Settings.data.systemMonitor.memCriticalThreshold + "%"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.topMargin: 10
      spacing: 4

      Text {
        text: "DISK"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
      }
      SettingRow {
        label: "Warning"
        NSlider {
          Layout.preferredWidth: 160
          from: 30
          to: 99
          stepSize: 1
          value: Settings.data.systemMonitor.diskWarningThreshold
          onMoved: value => Settings.data.systemMonitor.diskWarningThreshold = Math.round(value)
        }
        Text {
          text: Settings.data.systemMonitor.diskWarningThreshold + "%"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
        }
      }
      SettingRow {
        label: "Critical"
        NSlider {
          Layout.preferredWidth: 160
          from: 30
          to: 100
          stepSize: 1
          value: Settings.data.systemMonitor.diskCriticalThreshold
          onMoved: value => Settings.data.systemMonitor.diskCriticalThreshold = Math.round(value)
        }
        Text {
          text: Settings.data.systemMonitor.diskCriticalThreshold + "%"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.topMargin: 10
      spacing: 4

      Text {
        text: "TEMP"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
      }
      SettingRow {
        label: "Warning"
        NSlider {
          Layout.preferredWidth: 160
          from: 30
          to: 99
          stepSize: 1
          value: Settings.data.systemMonitor.tempWarningThreshold
          onMoved: value => Settings.data.systemMonitor.tempWarningThreshold = Math.round(value)
        }
        Text {
          text: Settings.data.systemMonitor.tempWarningThreshold + "%"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
        }
      }
      SettingRow {
        label: "Critical"
        NSlider {
          Layout.preferredWidth: 160
          from: 30
          to: 100
          stepSize: 1
          value: Settings.data.systemMonitor.tempCriticalThreshold
          onMoved: value => Settings.data.systemMonitor.tempCriticalThreshold = Math.round(value)
        }
        Text {
          text: Settings.data.systemMonitor.tempCriticalThreshold + "%"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
        }
      }
    }
  }
  }
}
