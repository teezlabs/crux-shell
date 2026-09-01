import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
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
    title: "Interface"
    description: "The font and overall size used across the shell."

    SettingRow {
      label: "Font family"

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

        // Intentionally rendered in the font it names, as a live preview —
        // the one place in the settings panel that doesn't use Tokens'
        // fixed JetBrains Mono, since previewing the actual chosen font is
        // the whole point of this field.
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
          selectByMouse: true
          onEditingFinished: Settings.data.ui.fontFamily = text
        }
      }

      Text {
        readonly property bool installed: Qt.fontFamilies().indexOf(fontInput.text) !== -1
        text: installed ? "✓ installed" : "not installed — falls back"
        color: installed ? Color.primary : Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.captionSize
      }
    }

    SettingRow {
      label: "UI scale"

      NSlider {
        Layout.preferredWidth: 160
        from: 0.8
        to: 1.4
        stepSize: 0.05
        value: Settings.data.ui.fontScale
        onMoved: value => Settings.data.ui.fontScale = value
      }

      Text {
        text: Math.round(Settings.data.ui.fontScale * 100) + "%"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }
  }

  SettingsSection {
    title: "crux"
    description: "Where crux's config and settings files live on disk."

    GridLayout {
      columns: 2
      rowSpacing: 8
      columnSpacing: 16

      Text {
        text: "Config"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
      Text {
        text: Quickshell.shellDir
        color: Color.surfaceText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }

      Text {
        text: "Settings"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
      Text {
        text: Settings.settingsFile
        color: Color.surfaceText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }
  }

  SettingsSection {
    title: "Reload"
    description: "Reloads every widget and settings page — use after editing a .qml file by hand outside this session."

    RowLayout {
      spacing: 10

      Item {
        width: restartLabel.implicitWidth + 24
        height: 30

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: restartHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer
          strokeColor: Color.outline
          strokeWidth: Tokens.borderModule
        }

        Text {
          id: restartLabel
          anchors.centerIn: parent
          text: "Restart crux"
          color: Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
        }

        HoverHandler {
          id: restartHover
          cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
          onTapped: Quickshell.execDetached(["bash", "-c", "pkill -f 'qs -c crux'; sleep 0.5; nohup qs -c crux >/dev/null 2>&1 & disown"])
        }
      }
    }
  }
  }
}
