import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

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
    title: "Typography"
    description: "The font used across the bar, popups, and this settings panel."

    SettingRow {
      label: "Font"
      Item {
        Layout.preferredWidth: 200
        height: 28

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: Color.surface
          strokeColor: fontInput.activeFocus ? Color.primary : Color.outline
          strokeWidth: Tokens.borderModule
        }

        TextInput {
          id: fontInput
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          verticalAlignment: Text.AlignVCenter
          text: Settings.data.ui.fontFamily
          color: Color.surfaceText
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: Tokens.bodySmSize
          onEditingFinished: Settings.data.ui.fontFamily = text
        }
      }
    }
  }

  SettingsSection {
    title: "Transparency"
    description: "How see-through the bar's modules are by default."

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
      NText {
        text: Math.round(Settings.data.theme.barOpacity * 100) + "%"
        color: Color.labelText
        size: NText.Size.BodySm
      }
    }
  }
  }
}
