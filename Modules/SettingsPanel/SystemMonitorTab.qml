import QtQuick
import QtQuick.Layouts
import qs.Commons
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
    title: "Sampling"
    description: "How often CPU/RAM are polled, and the usage level that flags them as high."

    SettingRow {
      label: "Refresh"
      NValueSlider {
        from: 500
        to: 10000
        stepSize: 500
        value: Settings.data.systemMonitor.refreshInterval
        sliderWidth: 200
        readoutText: (Settings.data.systemMonitor.refreshInterval / 1000).toFixed(1) + "s"
        onMoved: value => Settings.data.systemMonitor.refreshInterval = Math.round(value)
      }
    }

  }

  SettingsSection {
    title: "Thresholds"
    description: "Per-metric warning/critical usage levels — CPU, RAM, disk, and temperature don't all warrant the same cutoff."

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 4

      NText {
        tracking: true
        text: "CPU"
        color: Color.labelText
        size: NText.Size.LabelXs
      }
      SettingRow {
        label: "Warning"
        NValueSlider {
          from: 30
          to: 99
          stepSize: 1
          value: Settings.data.systemMonitor.cpuWarningThreshold
          sliderWidth: 160
          readoutText: Settings.data.systemMonitor.cpuWarningThreshold + "%"
          onMoved: value => Settings.data.systemMonitor.cpuWarningThreshold = Math.round(value)
        }
      }
      SettingRow {
        label: "Critical"
        NValueSlider {
          from: 30
          to: 100
          stepSize: 1
          value: Settings.data.systemMonitor.cpuCriticalThreshold
          sliderWidth: 160
          readoutText: Settings.data.systemMonitor.cpuCriticalThreshold + "%"
          onMoved: value => Settings.data.systemMonitor.cpuCriticalThreshold = Math.round(value)
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.topMargin: 10
      spacing: 4

      NText {
        tracking: true
        text: "RAM"
        color: Color.labelText
        size: NText.Size.LabelXs
      }
      SettingRow {
        label: "Warning"
        NValueSlider {
          from: 30
          to: 99
          stepSize: 1
          value: Settings.data.systemMonitor.memWarningThreshold
          sliderWidth: 160
          readoutText: Settings.data.systemMonitor.memWarningThreshold + "%"
          onMoved: value => Settings.data.systemMonitor.memWarningThreshold = Math.round(value)
        }
      }
      SettingRow {
        label: "Critical"
        NValueSlider {
          from: 30
          to: 100
          stepSize: 1
          value: Settings.data.systemMonitor.memCriticalThreshold
          sliderWidth: 160
          readoutText: Settings.data.systemMonitor.memCriticalThreshold + "%"
          onMoved: value => Settings.data.systemMonitor.memCriticalThreshold = Math.round(value)
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.topMargin: 10
      spacing: 4

      NText {
        tracking: true
        text: "DISK"
        color: Color.labelText
        size: NText.Size.LabelXs
      }
      SettingRow {
        label: "Warning"
        NValueSlider {
          from: 30
          to: 99
          stepSize: 1
          value: Settings.data.systemMonitor.diskWarningThreshold
          sliderWidth: 160
          readoutText: Settings.data.systemMonitor.diskWarningThreshold + "%"
          onMoved: value => Settings.data.systemMonitor.diskWarningThreshold = Math.round(value)
        }
      }
      SettingRow {
        label: "Critical"
        NValueSlider {
          from: 30
          to: 100
          stepSize: 1
          value: Settings.data.systemMonitor.diskCriticalThreshold
          sliderWidth: 160
          readoutText: Settings.data.systemMonitor.diskCriticalThreshold + "%"
          onMoved: value => Settings.data.systemMonitor.diskCriticalThreshold = Math.round(value)
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.topMargin: 10
      spacing: 4

      NText {
        tracking: true
        text: "TEMP"
        color: Color.labelText
        size: NText.Size.LabelXs
      }
      SettingRow {
        label: "Warning"
        NValueSlider {
          from: 30
          to: 99
          stepSize: 1
          value: Settings.data.systemMonitor.tempWarningThreshold
          sliderWidth: 160
          readoutText: Settings.data.systemMonitor.tempWarningThreshold + "%"
          onMoved: value => Settings.data.systemMonitor.tempWarningThreshold = Math.round(value)
        }
      }
      SettingRow {
        label: "Critical"
        NValueSlider {
          from: 30
          to: 100
          stepSize: 1
          value: Settings.data.systemMonitor.tempCriticalThreshold
          sliderWidth: 160
          readoutText: Settings.data.systemMonitor.tempCriticalThreshold + "%"
          onMoved: value => Settings.data.systemMonitor.tempCriticalThreshold = Math.round(value)
        }
      }
    }
  }
  }
}
