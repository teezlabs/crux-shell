import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.SettingsPanel.Controls

ColumnLayout {
  id: root
  spacing: 20

  SettingsSection {
    title: "Typography"

    SettingRow {
      label: "Font"
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
          color: Color.mSurface
          radius: Style.radiusXXS
        }
      }
    }
  }

  SettingsSection {
    title: "Shape & transparency"

    SettingRow {
      label: "Corner radius"
      NSlider {
        Layout.preferredWidth: 200
        from: 0
        to: 3
        stepSize: 0.1
        value: Settings.data.theme.radiusRatio
        onMoved: value => Settings.data.theme.radiusRatio = value
      }
      Text {
        text: Settings.data.theme.radiusRatio.toFixed(1) + "x"
        color: Color.mOnSurfaceVariant
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Style.fontSizeS
      }
    }

    SettingRow {
      label: "Bar opacity"
      NSlider {
        Layout.preferredWidth: 200
        from: 0.2
        to: 1
        stepSize: 0.05
        value: Settings.data.theme.barOpacity
        onMoved: value => Settings.data.theme.barOpacity = value
      }
      Text {
        text: Math.round(Settings.data.theme.barOpacity * 100) + "%"
        color: Color.mOnSurfaceVariant
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: Style.fontSizeS
      }
    }
  }

  Item {
    Layout.fillHeight: true
  }
}
