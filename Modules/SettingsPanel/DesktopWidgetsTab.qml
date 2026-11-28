import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Desktop cards: master and per-card switches, and a reset that returns a card to its default corner.
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

  SettingsSection {
    title: "Desktop Widgets"
    description: "Cards drawn on the desktop, below every window: weather, now playing and the Control Center. Drag any of them anywhere on screen; each remembers where you leave it."

    SettingRow {
      label: "Enabled"
      NToggle {
        checked: Settings.data.desktopWidgets.enabled
        onToggled: checked => Settings.data.desktopWidgets.enabled = checked
      }
    }
  }

  SettingsSection {
    title: "Weather card"
    description: "Toggle it on/off, or snap it back to its default corner."

    SettingRow {
      label: "Show"
      NToggle {
        checked: Settings.data.desktopWidgets.weatherEnabled
        onToggled: checked => Settings.data.desktopWidgets.weatherEnabled = checked
      }
    }

    SettingRow {
      label: "Position"
      Item {
        width: resetWeatherLabel.implicitWidth + 24
        height: 28

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: resetWeatherHover.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer
          strokeColor: Colors.outline
          strokeWidth: Tokens.borderModule
        }

        NText {
          id: resetWeatherLabel
          anchors.centerIn: parent
          text: "Reset position"
          color: Colors.surfaceText
          size: NText.Size.BodySm
        }

        HoverHandler {
          id: resetWeatherHover
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: {
            Settings.data.desktopWidgets.weatherX = -1;
            Settings.data.desktopWidgets.weatherY = -1;
          }
        }
      }
    }
  }

  SettingsSection {
    title: "Media card"
    description: "Toggle it on/off, or snap it back to its default corner."

    SettingRow {
      label: "Show"
      NToggle {
        checked: Settings.data.desktopWidgets.mediaEnabled
        onToggled: checked => Settings.data.desktopWidgets.mediaEnabled = checked
      }
    }

    SettingRow {
      label: "Position"
      Item {
        width: resetMediaLabel.implicitWidth + 24
        height: 28

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: resetMediaHover.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer
          strokeColor: Colors.outline
          strokeWidth: Tokens.borderModule
        }

        NText {
          id: resetMediaLabel
          anchors.centerIn: parent
          text: "Reset position"
          color: Colors.surfaceText
          size: NText.Size.BodySm
        }

        HoverHandler {
          id: resetMediaHover
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: {
            Settings.data.desktopWidgets.mediaX = -1;
            Settings.data.desktopWidgets.mediaY = -1;
          }
        }
      }
    }
  }

  SettingsSection {
    title: "Control Center card"
    description: "The full Control Center on the desktop. Drag it by the dotted strip on top. Its live stats, pings and visualizer pause while windows cover it."

    SettingRow {
      label: "Show"
      NToggle {
        checked: Settings.data.desktopWidgets.controlCenterEnabled
        onToggled: checked => Settings.data.desktopWidgets.controlCenterEnabled = checked
      }
    }

    SettingRow {
      label: "Monitor"
      NSegmented {
        model: Quickshell.screens.map(s => ({
              "key": s.name,
              "label": s.name
            }))
        currentKey: Settings.data.desktopWidgets.controlCenterScreen !== "" ? Settings.data.desktopWidgets.controlCenterScreen : (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "")
        uppercase: false
        onSelected: key => {
          Settings.data.desktopWidgets.controlCenterScreen = key;
          Settings.data.desktopWidgets.controlCenterX = -1;
          Settings.data.desktopWidgets.controlCenterY = -1;
        }
      }
    }

    SettingRow {
      label: "Position"
      Item {
        width: resetCcLabel.implicitWidth + 24
        height: 28

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: resetCcHover.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer
          strokeColor: Colors.outline
          strokeWidth: Tokens.borderModule
        }

        NText {
          id: resetCcLabel
          anchors.centerIn: parent
          text: "Reset position"
          color: Colors.surfaceText
          size: NText.Size.BodySm
        }

        HoverHandler {
          id: resetCcHover
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: {
            Settings.data.desktopWidgets.controlCenterX = -1;
            Settings.data.desktopWidgets.controlCenterY = -1;
          }
        }
      }
    }
  }
  }
}
