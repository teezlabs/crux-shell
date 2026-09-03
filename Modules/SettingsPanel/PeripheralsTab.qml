import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Settings for the KeyboardLayout, LockKeys, and VPN bar widgets — grouped
// here rather than three near-empty tabs, matching how Audio already
// groups everything Pipewire-related into one tab.
NScrollView {
  id: root
  contentHeight: col.implicitHeight

  // -------------------- Keyboard device --------------------
  property var keyboards: []

  Process {
    id: devicesProc
    command: ["hyprctl", "-j", "devices"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var data = JSON.parse(text);
          root.keyboards = data.keyboards || [];
        } catch (e) {
          root.keyboards = [];
        }
      }
    }
  }

  Component.onCompleted: devicesProc.running = true

  // -------------------- VPN --------------------
  property var vpnConnections: ({})
  readonly property var vpnList: {
    var l = [];
    for (var uuid in root.vpnConnections)
      l.push(root.vpnConnections[uuid]);
    return l;
  }

  Process {
    id: vpnProc
    command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,DEVICE", "connection", "show"]
    stdout: StdioCollector {
      onStreamFinished: {
        var map = {};
        var lines = text.split("\n");
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim();
          if (!line)
            continue;
          var lastColon = line.lastIndexOf(":");
          if (lastColon === -1)
            continue;
          var device = line.substring(lastColon + 1);
          var rest = line.substring(0, lastColon);
          var c2 = rest.lastIndexOf(":");
          if (c2 === -1)
            continue;
          var type = rest.substring(c2 + 1);
          if (type !== "vpn" && type !== "wireguard")
            continue;
          var rest2 = rest.substring(0, c2);
          var c3 = rest2.lastIndexOf(":");
          if (c3 === -1)
            continue;
          var uuid = rest2.substring(c3 + 1);
          var name = rest2.substring(0, c3);
          if (!uuid || !name)
            continue;
          map[uuid] = {
            "uuid": uuid,
            "name": name,
            "device": device,
            "active": !!device && device !== "--"
          };
        }
        root.vpnConnections = map;
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!vpnProc.running)
      vpnProc.running = true
  }

  Process {
    id: vpnToggleProc
    property string mode: "up"
    property string uuid: ""
    command: ["nmcli", "connection", mode, "uuid", uuid]
    stdout: StdioCollector {
      onStreamFinished: vpnProc.running = true
    }
  }

  ColumnLayout {
    id: col
    width: parent.width - 4
    spacing: 20

    SettingsSection {
      title: "Keyboard"
      description: "Which physical keyboard the KeyboardLayout and LockKeys bar widgets track — auto-detects Hyprland's \"main\" device when left on Auto."

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
          model: [{
            "name": "",
            "label": "Auto-detect"
          }].concat(root.keyboards.map(function (k) {
            return {
              "name": k.name,
              "label": k.name + (k.main ? "  (main)" : "")
            };
          }))

          delegate: Item {
            id: kbRow
            required property var modelData
            Layout.fillWidth: true
            height: 30
            readonly property bool isSelected: Settings.data.keyboard.deviceName === kbRow.modelData.name

            Rectangle {
              anchors.fill: parent
              color: kbRow.isSelected ? Color.primaryContainer : (kbHover.hovered ? Color.surfaceContainerHigh : "transparent")
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8

              Text {
                text: kbRow.isSelected ? "●" : "○"
                color: kbRow.isSelected ? Color.primary : Color.labelText
                font.pixelSize: Tokens.bodySmSize
              }
              NText {
                text: kbRow.modelData.label
                color: kbRow.isSelected ? Color.primaryContainerText : Color.surfaceText
                size: NText.Size.BodySm
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            HoverHandler {
              id: kbHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: Settings.data.keyboard.deviceName = kbRow.modelData.name
            }
          }
        }

        NText {
          visible: root.keyboards.length === 0
          text: "hyprctl reported no keyboard devices."
          color: Color.labelText
          size: NText.Size.BodySm
        }
      }
    }

    // -------------------- Lock keys --------------------
    SettingsSection {
      title: "Lock keys"
      description: "Caps/Num Lock come from Hyprland's own device state. Scroll Lock has no data source on this system (no LED sysfs node), so its indicator always shows as unavailable."

      SettingRow {
        label: "Show Caps Lock"
        NToggle {
          checked: Settings.data.lockKeys.showCapsLock
          onToggled: checked => Settings.data.lockKeys.showCapsLock = checked
        }
      }
      SettingRow {
        label: "Show Num Lock"
        NToggle {
          checked: Settings.data.lockKeys.showNumLock
          onToggled: checked => Settings.data.lockKeys.showNumLock = checked
        }
      }
      SettingRow {
        label: "Show Scroll Lock"
        NToggle {
          checked: Settings.data.lockKeys.showScrollLock
          onToggled: checked => Settings.data.lockKeys.showScrollLock = checked
        }
      }
      SettingRow {
        label: "Hide when off"
        NToggle {
          checked: Settings.data.lockKeys.hideWhenOff
          onToggled: checked => Settings.data.lockKeys.hideWhenOff = checked
        }
      }
    }

    SettingsSection {
      title: "VPN connections"
      description: "NetworkManager connection profiles of type vpn/wireguard — click to connect or disconnect."

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
          model: root.vpnList

          delegate: Item {
            id: vpnRow
            required property var modelData
            Layout.fillWidth: true
            height: 32

            Rectangle {
              anchors.fill: parent
              color: vpnRow.modelData.active ? Color.primaryContainer : (vpnHover.hovered ? Color.surfaceContainerHigh : "transparent")
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 8
              anchors.rightMargin: 8

              Text {
                text: vpnRow.modelData.active ? "●" : "○"
                color: vpnRow.modelData.active ? Color.primary : Color.labelText
                font.pixelSize: Tokens.bodySmSize
              }
              NText {
                text: vpnRow.modelData.name
                color: vpnRow.modelData.active ? Color.primaryContainerText : Color.surfaceText
                size: NText.Size.BodySm
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
              NText {
                text: vpnRow.modelData.active ? "connected" : "disconnected"
                color: Color.labelText
                size: NText.Size.Caption
              }
            }

            HoverHandler {
              id: vpnHover
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: {
                vpnToggleProc.mode = vpnRow.modelData.active ? "down" : "up";
                vpnToggleProc.uuid = vpnRow.modelData.uuid;
                vpnToggleProc.running = true;
              }
            }
          }
        }

        NText {
          visible: root.vpnList.length === 0
          text: "No VPN/WireGuard connection profiles found (nmcli connection show)."
          color: Color.labelText
          size: NText.Size.BodySm
        }
      }
    }

    Item {
      Layout.fillHeight: true
    }
  }
}
