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
      text: "Font"
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
      Layout.preferredWidth: 90
    }
    TextInput {
      Layout.preferredWidth: 200
      text: Settings.data.ui.fontFamily
      color: Color.mOnSurface
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
      onEditingFinished: Settings.data.ui.fontFamily = text

      Rectangle {
        z: -1
        anchors.fill: parent
        anchors.margins: -4
        color: Color.mSurfaceVariant
        radius: Style.radiusXXS
      }
    }
  }

  RowLayout {
    spacing: 10
    Text {
      text: "Corner radius"
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
      Layout.preferredWidth: 90
    }
    Slider {
      Layout.preferredWidth: 200
      from: 0
      to: 3
      stepSize: 0.1
      value: Settings.data.theme.radiusRatio
      onMoved: Settings.data.theme.radiusRatio = value
    }
    Text {
      text: Settings.data.theme.radiusRatio.toFixed(1) + "x"
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
    }
  }

  RowLayout {
    spacing: 10
    Text {
      text: "Bar opacity"
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
      Layout.preferredWidth: 90
    }
    Slider {
      Layout.preferredWidth: 200
      from: 0.2
      to: 1
      stepSize: 0.05
      value: Settings.data.theme.barOpacity
      onMoved: Settings.data.theme.barOpacity = value
    }
    Text {
      text: Math.round(Settings.data.theme.barOpacity * 100) + "%"
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: Style.fontSizeS
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
