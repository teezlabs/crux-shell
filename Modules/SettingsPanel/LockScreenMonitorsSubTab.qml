import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
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
      title: "Interactive monitors"
    description: "Which screens show the clock/password field/status row/notifications. Off on every monitor = show on all. A screen not listed still locks (blurred+dimmed wallpaper, real session grab) — it just shows no unlock form of its own."

    ColumnLayout {
      spacing: 10

      Repeater {
        model: Quickshell.screens

        delegate: RowLayout {
          required property var modelData
          readonly property bool enabled_: Settings.data.lockScreen.monitors.length === 0 || Settings.data.lockScreen.monitors.includes(modelData.name)
          spacing: 10

          NToggle {
            checked: parent.enabled_
            onToggled: {
              var list = Settings.data.lockScreen.monitors.slice();
              var name = parent.modelData.name;
              if (list.length === 0) {
                var all = [];
                for (var i = 0; i < Quickshell.screens.length; i++)
                  if (Quickshell.screens[i].name !== name)
                    all.push(Quickshell.screens[i].name);
                Settings.data.lockScreen.monitors = all;
              } else {
                var idx = list.indexOf(name);
                if (idx >= 0)
                  list.splice(idx, 1);
                else
                  list.push(name);
                if (list.length === Quickshell.screens.length)
                  list = [];
                Settings.data.lockScreen.monitors = list;
              }
            }
          }

          Text {
            text: modelData.name
            color: Color.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodySmSize
          }
        }
      }

      Text {
        visible: Quickshell.screens.length === 0
        text: "No monitors detected."
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
      }
    }
  }

    Item {
      Layout.fillHeight: true
    }
  }
}
