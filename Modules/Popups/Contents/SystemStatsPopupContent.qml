import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.ControlCenter
import qs.Modules.Popups

// Full system telemetry from SystemStats: per-core CPU, memory, temperature, every real filesystem and load.
ColumnLayout {
  id: root

  spacing: Tokens.spaceLg

  // Bound to the owning SlideCard's `shown` from PopupHost; samples the full stats only while open.
  property bool active: false
  onActiveChanged: SystemStats.fullWatchers += active ? 1 : -1
  Component.onDestruction: if (active)
    SystemStats.fullWatchers--

  readonly property real cpuPercent: SystemStats.cpuPercent
  readonly property var coresUsage: SystemStats.coresUsage
  readonly property real memPercent: SystemStats.memPercent
  readonly property real memUsedGb: SystemStats.memUsedGb
  readonly property real memTotalGb: SystemStats.memTotalGb
  readonly property real tempC: SystemStats.tempC
  readonly property var disks: SystemStats.disks
  readonly property string uptimeText: SystemStats.formatUptime("d")
  readonly property real loadAvg1: SystemStats.loadAvg1
  readonly property real loadAvg5: SystemStats.loadAvg5
  readonly property real loadAvg15: SystemStats.loadAvg15

  // ---- Header ----
  PopupHeader {
    title: "SYSTEM STATS"
    meta: "Up " + root.uptimeText
  }

  // ---- CPU + MEM + TEMP dials ----
  RowLayout {
    Layout.fillWidth: true
    spacing: 18

    CircularGauge {
      percent: root.cpuPercent
      value: Math.round(root.cpuPercent) + "%"
      label: "CPU"
    }
    CircularGauge {
      percent: root.memPercent
      value: root.memUsedGb.toFixed(1) + "G"
      label: "MEM"
    }
    CircularGauge {
      percent: Math.min(100, root.tempC)
      fillColor: Colors.tertiary
      value: Math.round(root.tempC) + "°"
      label: "TEMP"
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 2
      NText {
        text: "MEM " + root.memUsedGb.toFixed(1) + " / " + root.memTotalGb.toFixed(1) + " GB"
        color: Colors.surfaceText
        size: NText.Size.BodySm
      }
      NText {
        text: "LOAD " + root.loadAvg1.toFixed(2) + " • " + root.loadAvg5.toFixed(2) + " • " + root.loadAvg15.toFixed(2)
        color: Colors.labelText
        size: NText.Size.Caption
      }
    }
  }

  // ---- Per-core CPU breakdown ----
  ColumnLayout {
    Layout.fillWidth: true
    spacing: 4
    visible: root.coresUsage.length > 0

    NText {
      tracking: true
      text: "CORES (" + root.coresUsage.length + ")"
      color: Colors.labelText
      size: NText.Size.LabelXs
    }

    Item {
      id: coreChart
      Layout.fillWidth: true
      Layout.preferredHeight: 32

      Row {
        anchors.fill: parent
        spacing: 3

        Repeater {
          model: root.coresUsage.length

          delegate: Item {
            required property int index
            width: Math.max(2, (coreChart.width - (root.coresUsage.length - 1) * 3) / root.coresUsage.length)
            height: coreChart.height

            Rectangle {
              anchors.bottom: parent.bottom
              width: parent.width
              height: Math.max(2, parent.height * (Math.min(100, root.coresUsage[index]) / 100))
              color: root.coresUsage[index] >= 85 ? Colors.error : Colors.primary

              Behavior on height {
                NumberAnimation {
                  duration: Tokens.durationMeterFill
                  easing.type: Tokens.easingMeterFill
                }
              }
            }
          }
        }
      }
    }
  }

  // ---- Disk: every real mounted filesystem ----
  ColumnLayout {
    Layout.fillWidth: true
    spacing: 8
    visible: root.disks.length > 0

    NText {
      tracking: true
      text: "DISK"
      color: Colors.labelText
      size: NText.Size.LabelXs
    }

    Repeater {
      model: root.disks

      delegate: ColumnLayout {
        required property var modelData
        Layout.fillWidth: true
        spacing: 2

        RowLayout {
          Layout.fillWidth: true
          NText {
            text: modelData.target
            color: Colors.surfaceText
            size: NText.Size.BodySm
            elide: Text.ElideMiddle
            Layout.fillWidth: true
          }
          NText {
            text: modelData.usedGb.toFixed(1) + " / " + modelData.sizeGb.toFixed(1) + " GB (" + modelData.percent + "%)"
            color: Colors.labelText
            size: NText.Size.Caption
          }
        }

        SegMeter {
          Layout.fillWidth: true
          cellCount: Tokens.meterTelemetryCells
          cellHeight: Tokens.meterTelemetryCellHeight
          value: modelData.percent
          interactive: false
          filledColor: modelData.percent >= 90 ? Colors.error : Colors.primary
          emptyColor: Colors.surfaceContainerHigh
        }
      }
    }
  }
}
