import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
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
    title: "Typography"
    description: "The font used across the bar, popups, and this settings panel."

    SettingRow {
      label: "Font"
      NTextInput {
        id: fontInput
        Layout.preferredWidth: 200
        height: 28
        fontFamily: Settings.data.ui.fontFamily
        text: Settings.data.ui.fontFamily
        onEditingFinished: Settings.data.ui.fontFamily = text
      }
    }
  }

  SettingsSection {
    title: "Transparency"
    description: "How see-through the bar's modules are by default."

    SettingRow {
      label: "Bar opacity"
      NValueSlider {
        from: 0.2
        to: 1
        stepSize: 0.05
        value: Settings.data.theme.barOpacity
        sliderWidth: 200
        readoutText: Math.round(Settings.data.theme.barOpacity * 100) + "%"
        onMoved: value => Settings.data.theme.barOpacity = value
      }
    }
  }
  }
}
