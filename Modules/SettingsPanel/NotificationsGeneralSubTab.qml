import QtQuick
import QtQuick.Layouts
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
      title: "Popups"
      description: "Turn popups on or off, mute them temporarily, and cap how many stack at once."

    SettingRow {
      label: "Enabled"
      NToggle {
        checked: Settings.data.notifications.enabled
        onToggled: checked => Settings.data.notifications.enabled = checked
      }
      Text {
        text: "Off disables the live popup stack only — history still logs every real notification."
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.captionSize
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
    }

    SettingRow {
      label: "Do not disturb"
      NToggle {
        checked: Settings.data.notifications.doNotDisturb
        onToggled: checked => Settings.data.notifications.doNotDisturb = checked
      }
      Text {
        text: "Temporary — suppresses popups without turning them off entirely."
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.captionSize
      }
    }

    SettingRow {
      label: "Max visible"
      NSlider {
        Layout.preferredWidth: 140
        from: 1
        to: 8
        stepSize: 1
        value: Settings.data.notifications.maxVisible
        onMoved: value => Settings.data.notifications.maxVisible = value
      }
      Text {
        text: Settings.data.notifications.maxVisible + " at once"
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }
  }

  SettingsSection {
    title: "Position"
    description: "Which corner of the screen new popups appear in."

    RowLayout {
      spacing: 6

      Repeater {
        model: [
          {
            "id": "top_left",
            "label": "Top left"
          },
          {
            "id": "top_right",
            "label": "Top right"
          },
          {
            "id": "bottom_left",
            "label": "Bottom left"
          },
          {
            "id": "bottom_right",
            "label": "Bottom right"
          }
        ]
        delegate: Item {
          id: posTile
          required property var modelData
          readonly property bool active: Settings.data.notifications.position === modelData.id
          Layout.preferredWidth: 96
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
            text: posTile.modelData.label.toUpperCase()
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
            onTapped: Settings.data.notifications.position = posTile.modelData.id
          }
        }
      }
    }
  }

    Item {
      Layout.fillHeight: true
    }
  }
}
