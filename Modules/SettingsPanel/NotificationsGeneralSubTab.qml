import QtQuick
import QtQuick.Layouts
import Quickshell
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
      title: "Popups"
      description: "Turn popups on or off, mute them temporarily, and cap how many stack at once."

    SettingRow {
      label: "Enabled"
      NToggle {
        checked: Settings.data.notifications.enabled
        onToggled: checked => Settings.data.notifications.enabled = checked
      }
      NText {
        text: "Off disables the live popup stack only — history still logs every real notification."
        color: Color.labelText
        size: NText.Size.Caption
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
      NText {
        text: "Temporary — suppresses popups without turning them off entirely."
        color: Color.labelText
        size: NText.Size.Caption
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
      NText {
        text: Settings.data.notifications.maxVisible + " at once"
        color: Color.labelText
        size: NText.Size.BodySm
      }
    }
  }

  SettingsSection {
    title: "Position"
    description: "Which corner of the screen new popups appear in."

    NSegmented {
      model: [
        {
          "key": "top_left",
          "label": "Top left"
        },
        {
          "key": "top_right",
          "label": "Top right"
        },
        {
          "key": "bottom_left",
          "label": "Bottom left"
        },
        {
          "key": "bottom_right",
          "label": "Bottom right"
        }
      ]
      currentKey: Settings.data.notifications.position
      tileWidth: 96
      onSelected: key => Settings.data.notifications.position = key
    }
  }

    SettingsSection {
      title: "Card"
      description: "Background opacity of the popup card itself."

      SettingRow {
        label: "Background opacity"
        NSlider {
          Layout.preferredWidth: 140
          from: 0.4
          to: 1
          stepSize: 0.02
          value: Settings.data.notifications.backgroundOpacity
          onMoved: value => Settings.data.notifications.backgroundOpacity = value
        }
        NText {
          text: Math.round(Settings.data.notifications.backgroundOpacity * 100) + "%"
          color: Color.labelText
          size: NText.Size.BodySm
        }
      }
    }

    SettingsSection {
      title: "Monitors"
      description: "Which screens show popups. None selected = all monitors."

      RowLayout {
        spacing: 6

        Repeater {
          model: Quickshell.screens

          delegate: Item {
            id: monTile
            required property var modelData
            readonly property bool active: Settings.data.notifications.monitors.length === 0 || Settings.data.notifications.monitors.includes(modelData.name)
            Layout.preferredWidth: monLabel.implicitWidth + 20
            height: 28

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: monTile.active ? Color.primaryContainer : (monHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer)
              strokeColor: monTile.active ? Color.primary : Color.outline
              strokeWidth: Tokens.borderModule
            }

            NText {
              tracking: true
              id: monLabel
              anchors.centerIn: parent
              text: monTile.modelData.name
              color: monTile.active ? Color.primaryContainerText : Color.surfaceText
              size: NText.Size.LabelXs
            }

            HoverHandler {
              id: monHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: {
                var list = Settings.data.notifications.monitors.slice();
                var name = monTile.modelData.name;
                if (list.length === 0) {
                  // Every monitor was implicitly on; toggling one off means
                  // explicitly listing every *other* monitor as on.
                  var all = [];
                  for (var i = 0; i < Quickshell.screens.length; i++)
                    if (Quickshell.screens[i].name !== name)
                      all.push(Quickshell.screens[i].name);
                  Settings.data.notifications.monitors = all;
                } else {
                  var idx = list.indexOf(name);
                  if (idx === -1)
                    list.push(name);
                  else
                    list.splice(idx, 1);
                  if (list.length === Quickshell.screens.length)
                    list = [];
                  Settings.data.notifications.monitors = list;
                }
              }
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
