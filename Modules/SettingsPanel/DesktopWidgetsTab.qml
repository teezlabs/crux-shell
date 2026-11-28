import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Desktop cards: master switch, edit mode and grid snapping, then each card's switch, options and reset.
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  // Returns a card to its default corner and size.
  component ResetButton: Item {
    id: reset
    required property string key
    width: resetLabel.implicitWidth + 24
    height: 28

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferIcon
      cutTopRight: true
      cutBottomLeft: true
      fillColor: resetHover.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer
      strokeColor: Colors.outline
      strokeWidth: Tokens.borderModule
    }
    NText {
      id: resetLabel
      anchors.centerIn: parent
      text: "Reset position and size"
      color: Colors.surfaceText
      size: NText.Size.BodySm
    }
    HoverHandler {
      id: resetHover
      cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
      onTapped: {
        Settings.data.desktopWidgets[reset.key + "X"] = -1;
        Settings.data.desktopWidgets[reset.key + "Y"] = -1;
        Settings.data.desktopWidgets[reset.key + "Scale"] = 1;
      }
    }
  }

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

    SettingsSection {
      title: "Desktop Widgets"
      description: "Cards drawn on the desktop, below every window. They stay put until you edit the layout: then a grid appears, and you can drag cards around and resize them from the square in their bottom-right corner."

      SettingRow {
        label: "Enabled"
        NToggle {
          checked: Settings.data.desktopWidgets.enabled
          onToggled: checked => Settings.data.desktopWidgets.enabled = checked
        }
      }

      SettingRow {
        label: "Layout"
        description: "Also: qs ipc -c crux call desktopWidgets toggleEdit"
        NButton {
          text: DesktopEdit.active ? "Done editing" : "Edit layout"
          enabled: Settings.data.desktopWidgets.enabled
          onClicked: {
            DesktopEdit.toggle();
            if (DesktopEdit.active)
              Popups.closeAll();
          }
        }
      }

      SettingRow {
        label: "Snap to grid"
        description: "Positions and sizes land on the grid while editing"
        NToggle {
          checked: Settings.data.desktopWidgets.gridSnap
          onToggled: checked => Settings.data.desktopWidgets.gridSnap = checked
        }
      }
    }

    SettingsSection {
      title: "Clock"
      description: "Big digits with a date line under them."

      SettingRow {
        label: "Show"
        NToggle {
          checked: Settings.data.desktopWidgets.clockEnabled
          onToggled: checked => Settings.data.desktopWidgets.clockEnabled = checked
        }
      }
      SettingRow {
        label: "Card background"
        description: "Off draws the digits straight on the wallpaper"
        NToggle {
          checked: Settings.data.desktopWidgets.clockCard
          onToggled: checked => Settings.data.desktopWidgets.clockCard = checked
        }
      }
      SettingRow {
        label: "Time format"
        description: "Qt format: HH:mm, HH:mm:ss, h:mm AP"
        NTextInput {
          Layout.preferredWidth: 180
          height: 28
          text: Settings.data.desktopWidgets.clockFormat
          onEditingFinished: Settings.data.desktopWidgets.clockFormat = text.trim() !== "" ? text : "HH:mm"
        }
      }
      SettingRow {
        label: "Date format"
        description: "Leave empty to hide the date"
        NTextInput {
          Layout.preferredWidth: 180
          height: 28
          text: Settings.data.desktopWidgets.clockDateFormat
          onEditingFinished: Settings.data.desktopWidgets.clockDateFormat = text
        }
      }
      SettingRow {
        label: "Position"
        ResetButton {
          key: "clock"
        }
      }
    }

    SettingsSection {
      title: "Music"
      description: "What's playing, with seek, transport and a visualizer. Hidden while nothing is playing."

      SettingRow {
        label: "Show"
        NToggle {
          checked: Settings.data.desktopWidgets.mediaEnabled
          onToggled: checked => Settings.data.desktopWidgets.mediaEnabled = checked
        }
      }
      SettingRow {
        label: "Card background"
        description: "Off draws it straight on the wallpaper"
        NToggle {
          checked: Settings.data.desktopWidgets.mediaCard
          onToggled: checked => Settings.data.desktopWidgets.mediaCard = checked
        }
      }
      SettingRow {
        label: "Position"
        ResetButton {
          key: "media"
        }
      }
    }

    SettingsSection {
      title: "Weather"
      description: "Now and the next four days."

      SettingRow {
        label: "Show"
        NToggle {
          checked: Settings.data.desktopWidgets.weatherEnabled
          onToggled: checked => Settings.data.desktopWidgets.weatherEnabled = checked
        }
      }
      SettingRow {
        label: "Card background"
        description: "Off draws it straight on the wallpaper"
        NToggle {
          checked: Settings.data.desktopWidgets.weatherCard
          onToggled: checked => Settings.data.desktopWidgets.weatherCard = checked
        }
      }
      SettingRow {
        label: "Position"
        ResetButton {
          key: "weather"
        }
      }
    }
  }
}
