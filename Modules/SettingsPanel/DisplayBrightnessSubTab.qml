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
    title: "Brightness"
    description: "Internal backlight only, via brightnessctl — no DDC/external-monitor or Apple Display control."

    SettingRow {
      label: "Scroll step"
      NValueSlider {
        from: 1
        to: 20
        stepSize: 1
        value: Settings.data.brightness.step
        sliderWidth: 200
        readoutText: Settings.data.brightness.step + "%"
        onMoved: value => Settings.data.brightness.step = Math.round(value)
      }
    }

    SettingRow {
      label: "Enforce minimum"
      NToggle {
        checked: Settings.data.brightness.enforceMinimum
        onToggled: checked => Settings.data.brightness.enforceMinimum = checked
      }
    }

    NText {
      text: "Keeps brightnessctl from ever setting the backlight all the way to 0% — a scroll-down that overshoots can't leave the screen unrecoverably black."
      color: Color.labelText
      size: NText.Size.Caption
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }
  }

    Item {
      Layout.fillHeight: true
    }
  }
}
