import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons

ColumnLayout {
  id: root
  spacing: 14

  RowLayout {
    spacing: 10
    Text {
      text: "Refresh"
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
      Layout.preferredWidth: 90
    }
    Slider {
      Layout.preferredWidth: 200
      from: 500
      to: 10000
      stepSize: 500
      value: Settings.data.systemMonitor.refreshInterval
      onMoved: Settings.data.systemMonitor.refreshInterval = Math.round(value)
    }
    Text {
      text: (Settings.data.systemMonitor.refreshInterval / 1000).toFixed(1) + "s"
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
    }
  }

  RowLayout {
    spacing: 10
    Text {
      text: "Warn at"
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
      Layout.preferredWidth: 90
    }
    Slider {
      Layout.preferredWidth: 200
      from: 50
      to: 100
      stepSize: 1
      value: Settings.data.systemMonitor.warnThreshold
      onMoved: Settings.data.systemMonitor.warnThreshold = Math.round(value)
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

  Item {
    Layout.fillHeight: true
  }
}
