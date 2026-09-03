import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Not a full network-manager UI — just autoconnect priority and Bluetooth
// discoverability, the two things the Wifi/Bluetooth popups don't expose.
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  property var savedNetworks: []

  function rescanSaved() {
    savedProc.running = true;
  }

  Process {
    id: savedProc
    command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,DEVICE,AUTOCONNECT,AUTOCONNECT-PRIORITY", "connection", "show"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var rows = [];
        var lines = text.split("\n");
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim();
          if (!line)
            continue;
          // Fields are colon-separated but NAME can itself contain colons,
          // so parse from the right — same approach PeripheralsTab.qml's
          // VPN list already uses for the same reason.
          var parts = line.split(":");
          if (parts.length < 6)
            continue;
          var priority = parts[parts.length - 1];
          var autoconnect = parts[parts.length - 2];
          var device = parts[parts.length - 3];
          var type = parts[parts.length - 4];
          var name = parts.slice(0, parts.length - 4).join(":");
          if (type !== "802-11-wireless")
            continue;
          rows.push({
            "name": name,
            "device": device,
            "active": !!device && device !== "--",
            "autoconnect": autoconnect === "yes",
            "priority": parseInt(priority) || 0
          });
        }
        rows.sort(function (a, b) {
          if (a.active !== b.active)
            return a.active ? -1 : 1;
          return a.name.localeCompare(b.name);
        });
        root.savedNetworks = rows;
      }
    }
  }

  Process {
    id: modifyProc
    onExited: root.rescanSaved()
  }

  function setAutoconnect(name, enabled) {
    modifyProc.command = ["nmcli", "connection", "modify", "id", name, "connection.autoconnect", enabled ? "yes" : "no"];
    modifyProc.running = true;
  }

  function setPriority(name, priority) {
    modifyProc.command = ["nmcli", "connection", "modify", "id", name, "connection.autoconnect-priority", String(priority)];
    modifyProc.running = true;
  }

  function forgetSaved(name) {
    modifyProc.command = ["nmcli", "connection", "delete", "id", name];
    modifyProc.running = true;
  }

  Timer {
    interval: 5000
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!savedProc.running)
      root.rescanSaved()
  }

  readonly property var btAdapter: Bluetooth.defaultAdapter

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

  SettingsSection {
    title: "Saved Wi-Fi networks"
    description: "Autoconnect priority (higher connects first when more than one saved network is in range) and removal — live scan/connect/forget for nearby networks are in the WI-FI popup, not here."

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 6

      Repeater {
        model: root.savedNetworks

        delegate: Item {
          id: netRow
          required property var modelData
          Layout.fillWidth: true
          height: 40

          Rectangle {
            anchors.fill: parent
            color: netHover.hovered ? Color.surfaceContainerHigh : "transparent"
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 10

            Text {
              text: netRow.modelData.active ? "●" : "○"
              color: netRow.modelData.active ? Color.primary : Color.labelText
              font.pixelSize: Tokens.bodySmSize
            }

            NText {
              text: netRow.modelData.name
              color: Color.surfaceText
              size: NText.Size.BodySm
              elide: Text.ElideRight
              Layout.preferredWidth: 160
            }

            NToggle {
              checked: netRow.modelData.autoconnect
              onToggled: checked => root.setAutoconnect(netRow.modelData.name, checked)
            }
            NText {
              tracking: true
              text: "AUTO"
              color: Color.labelText
              size: NText.Size.LabelXs
            }

            NSlider {
              Layout.preferredWidth: 100
              from: -10
              to: 10
              stepSize: 1
              value: netRow.modelData.priority
              onMoved: value => root.setPriority(netRow.modelData.name, Math.round(value))
            }
            NText {
              text: (netRow.modelData.priority > 0 ? "+" : "") + netRow.modelData.priority
              color: Color.labelText
              size: NText.Size.BodySm
              Layout.preferredWidth: 26
            }

            Item {
              Layout.fillWidth: true
            }

            Text {
              text: "×"
              color: forgetHover.hovered ? Color.error : Color.labelText
              font.pixelSize: Tokens.bodyLgSize
              HoverHandler {
                id: forgetHover
                cursorShape: Qt.PointingHandCursor
              }
              MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.forgetSaved(netRow.modelData.name)
              }
            }
          }

          HoverHandler {
            id: netHover
          }
        }
      }

      NText {
        visible: root.savedNetworks.length === 0
        text: "No saved Wi-Fi networks (nmcli connection show)."
        color: Color.labelText
        size: NText.Size.BodySm
      }
    }
  }

  SettingsSection {
    title: "Bluetooth"
    description: "Device pairing/connecting/forgetting is in the BLUETOOTH popup — this is the one adapter setting nothing else exposes."

    SettingRow {
      label: "Discoverable"
      enabled: !!root.btAdapter
      NToggle {
        checked: !!(root.btAdapter && root.btAdapter.discoverable)
        onToggled: checked => {
          if (root.btAdapter)
            root.btAdapter.discoverable = checked;
        }
      }
      NText {
        text: root.btAdapter ? "Other devices can see this machine while on" : "No adapter"
        color: Color.labelText
        size: NText.Size.Caption
      }
    }

    SettingRow {
      label: "Hide unnamed devices"
      NToggle {
        checked: Settings.data.bluetooth.hideUnnamedDevices
        onToggled: checked => Settings.data.bluetooth.hideUnnamedDevices = checked
      }
      NText {
        text: "Off shows devices still using a raw address/UUID as their name (useful mid-pairing)"
        color: Color.labelText
        size: NText.Size.Caption
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
      }
    }
  }
  }
}
