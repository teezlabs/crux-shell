import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls

// On-screen-display settings: crux's VolumeOsd.qml already runs reacting to
// live Pipewire state with no settings tab at all (position/duration were
// hardcoded). This is purely exposing what already exists.
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
    title: "Volume OSD"
    description: "Shown briefly whenever the default sink's volume or mute state changes, from any source (hardware keys, another app, this shell)."

    SettingRow {
      label: "Enabled"
      NToggle {
        checked: Settings.data.osd.enabled
        onToggled: checked => Settings.data.osd.enabled = checked
      }
    }

    SettingRow {
      label: "Position"

      RowLayout {
        spacing: 6

        Repeater {
          model: ["top", "center", "bottom"]
          delegate: Item {
            id: posTile
            required property string modelData
            readonly property bool active: Settings.data.osd.position === modelData
            Layout.preferredWidth: 70
            height: 28

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: posTile.active ? Color.primaryContainer : (posHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer)
              strokeColor: posTile.active ? Color.primary : Color.outline
              strokeWidth: Tokens.borderModule
            }

            Text {
              anchors.centerIn: parent
              text: posTile.modelData.toUpperCase()
              color: posTile.active ? Color.primaryContainerText : Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
              font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
            }

            HoverHandler {
              id: posHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: Settings.data.osd.position = posTile.modelData
            }
          }
        }
      }
    }

    SettingRow {
      label: "Duration"

      NSlider {
        Layout.preferredWidth: 160
        from: 500
        to: 3000
        stepSize: 100
        value: Settings.data.osd.durationMs
        onMoved: value => Settings.data.osd.durationMs = value
      }

      Text {
        text: Settings.data.osd.durationMs + " ms"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }
  }
  }
}
