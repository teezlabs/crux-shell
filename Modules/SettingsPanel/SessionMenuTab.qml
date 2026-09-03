import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Settings for the power-button's existing PowerMenuWindow.qml popup — no
// new UI surface, just exposing what was previously hardcoded: which
// actions show, and which need a second tap ("arm-then-confirm") before
// they actually run.
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  readonly property var allActions: ["Lock", "Suspend", "Logout", "Reboot", "Shutdown"]

  function toggleInList(listName, value) {
    var list = Settings.data.sessionMenu[listName].slice();
    var idx = list.indexOf(value);
    if (idx === -1)
      list.push(value);
    else
      list.splice(idx, 1);
    Settings.data.sessionMenu[listName] = list;
  }

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

  SettingsSection {
    title: "Actions"
    description: "Which buttons appear in the power menu, and which require a second tap before they run."

    ColumnLayout {
      spacing: 10
      Layout.fillWidth: true

      Repeater {
        model: root.allActions

        delegate: SettingRow {
          required property string modelData
          label: modelData

          RowLayout {
            spacing: 6
            NToggle {
              checked: Settings.data.sessionMenu.enabledActions.indexOf(modelData) !== -1
              onToggled: root.toggleInList("enabledActions", modelData)
            }
            NText {
              text: "shown"
              color: Color.labelText
              size: NText.Size.Caption
            }
          }

          RowLayout {
            spacing: 6
            NToggle {
              checked: Settings.data.sessionMenu.confirmActions.indexOf(modelData) !== -1
              onToggled: root.toggleInList("confirmActions", modelData)
            }
            NText {
              text: "confirm"
              color: Color.labelText
              size: NText.Size.Caption
            }
          }
        }
      }
    }
  }

  SettingsSection {
    title: "Confirm window"
    description: "How long a \"confirm\" action stays armed after the first tap before it resets."

    SettingRow {
      label: "Duration"
      NValueSlider {
        from: 1000
        to: 5000
        stepSize: 250
        value: Settings.data.sessionMenu.confirmWindowMs
        sliderWidth: 160
        readoutText: (Settings.data.sessionMenu.confirmWindowMs / 1000).toFixed(2) + "s"
        onMoved: value => Settings.data.sessionMenu.confirmWindowMs = Math.round(value)
      }
    }
  }
  }
}
