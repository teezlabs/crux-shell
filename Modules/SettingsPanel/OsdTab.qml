import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

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

      NSegmented {
        model: ["top", "center", "bottom"]
        currentKey: Settings.data.osd.position
        tileWidth: 70
        onSelected: key => Settings.data.osd.position = key
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

      NText {
        text: Settings.data.osd.durationMs + " ms"
        color: Color.labelText
        size: NText.Size.BodySm
      }
    }

    SettingRow {
      label: "Background opacity"
      NSlider {
        Layout.preferredWidth: 160
        from: 0.4
        to: 1
        stepSize: 0.02
        value: Settings.data.osd.backgroundOpacity
        onMoved: value => Settings.data.osd.backgroundOpacity = value
      }
      NText {
        text: Math.round(Settings.data.osd.backgroundOpacity * 100) + "%"
        color: Color.labelText
        size: NText.Size.BodySm
      }
    }
  }

  SettingsSection {
    title: "Monitors"
    description: "Which screens show the OSD. None selected = all monitors."

    RowLayout {
      spacing: 6

      Repeater {
        model: Quickshell.screens

        delegate: Item {
          id: monTile
          required property var modelData
          readonly property bool active: Settings.data.osd.monitors.length === 0 || Settings.data.osd.monitors.includes(modelData.name)
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
              var list = Settings.data.osd.monitors.slice();
              var name = monTile.modelData.name;
              if (list.length === 0) {
                var all = [];
                for (var i = 0; i < Quickshell.screens.length; i++)
                  if (Quickshell.screens[i].name !== name)
                    all.push(Quickshell.screens[i].name);
                Settings.data.osd.monitors = all;
              } else {
                var idx = list.indexOf(name);
                if (idx === -1)
                  list.push(name);
                else
                  list.splice(idx, 1);
                if (list.length === Quickshell.screens.length)
                  list = [];
                Settings.data.osd.monitors = list;
              }
            }
          }
        }
      }
    }
  }
  }
}
