import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import "BluetoothModel.js" as Model

// Bluetooth popup: real data/behavior ported from Omarchy's
// shell/plugins/panels/bluetooth Panel.qml + Model.js (same Quickshell.Bluetooth
// backend and omarchy-bluetooth-device/omarchy-bluetooth-power CLI helpers) —
// UI rebuilt on crux's own lean primitives instead of Omarchy's shared Ui kit.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var devices: Bluetooth.devices ? Bluetooth.devices.values : []
  readonly property var deviceGroups: Model.deviceLists(devices)
  readonly property var connectedDevices: deviceGroups.connected || []
  readonly property var knownDevices: deviceGroups.known || []
  readonly property var discoveredDevices: deviceGroups.discovered || []

  // address -> "connecting" | "disconnecting" | "forgetting"
  property var pendingActions: ({})

  readonly property string _binDir: Quickshell.env("HOME") + "/.config/quickshell/crux/bin/"

  function deviceFor(address) {
    for (var i = 0; i < devices.length; i++) {
      if (devices[i] && devices[i].address === address)
        return devices[i];
    }
    return null;
  }

  function setPendingAction(address, action) {
    if (!address)
      return;
    var next = Model.cloneMap(pendingActions);
    if (action)
      next[address] = action;
    else
      delete next[address];
    pendingActions = next;
  }

  function deviceCommand(action, address) {
    return [root._binDir + "omarchy-bluetooth-device", action, address];
  }

  function connectDevice(device) {
    if (!device || device.connected)
      return;
    var action = (device.paired || device.bonded || device.trusted) ? "connect" : "pair";
    setPendingAction(device.address, "connecting");
    Quickshell.execDetached(deviceCommand(action, device.address));
  }

  function disconnectDevice(device) {
    if (!device || !device.connected)
      return;
    setPendingAction(device.address, "disconnecting");
    if (device.disconnect)
      device.disconnect();
    Quickshell.execDetached(deviceCommand("disconnect", device.address));
  }

  function forgetDevice(device) {
    if (!device || !device.address)
      return;
    setPendingAction(device.address, "forgetting");
    Quickshell.execDetached(deviceCommand("forget", device.address));
  }

  function syncPendingActions() {
    var next = Model.cloneMap(pendingActions);
    var changed = false;
    for (var address in next) {
      var action = next[address];
      var found = deviceFor(address);
      var done = (action === "connecting" && found && found.connected) || (action === "disconnecting" && found && !found.connected) || (action === "forgetting" && (!found || (!found.paired && !found.bonded && !found.trusted)));
      if (done) {
        delete next[address];
        changed = true;
      }
    }
    if (changed)
      pendingActions = next;
  }

  onDevicesChanged: syncPendingActions()

  Timer {
    interval: 800
    repeat: true
    running: root.visible
    onTriggered: root.syncPendingActions()
  }

  function toggleBluetooth() {
    if (!adapter)
      return;
    Quickshell.execDetached([root._binDir + "omarchy-bluetooth-power", adapter.enabled ? "off" : "on"]);
  }

  // Discovery is a BlueZ session other clients may also hold; only stop it if
  // this popup was the one that started it.
  property bool owesDiscoveryStop: false

  onVisibleChanged: {
    if (visible) {
      if (adapter && adapter.enabled && !adapter.discovering) {
        adapter.discovering = true;
        owesDiscoveryStop = true;
      }
    } else if (owesDiscoveryStop && adapter && adapter.discovering) {
      adapter.discovering = false;
      owesDiscoveryStop = false;
    }
  }

  visible: false
  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-bluetooth-menu"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  function toggle() {
    visible = !visible;
  }

  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.visible = false
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.visible = false
  }

  Rectangle {
    id: card
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: 40
    anchors.rightMargin: 12
    width: 320
    height: Math.min(480, column.implicitHeight + 24)
    radius: 2
    color: "#1e1e2e"
    border.color: "#45475a"
    border.width: 1

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      id: column
      anchors.fill: parent
      anchors.margins: 12
      spacing: 8

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "Bluetooth"
          color: "#cdd6f4"
          font.pixelSize: 14
          font.bold: true
          Layout.fillWidth: true
        }

        Rectangle {
          width: 36
          height: 18
          radius: 2
          color: root.adapter && root.adapter.enabled ? "#89b4fa" : "#45475a"

          Rectangle {
            width: 14
            height: 14
            radius: 1
            color: "#1e1e2e"
            anchors.verticalCenter: parent.verticalCenter
            x: (root.adapter && root.adapter.enabled) ? parent.width - width - 2 : 2
            Behavior on x {
              NumberAnimation {
                duration: 120
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleBluetooth()
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        visible: !root.adapter || !root.adapter.enabled

        Text {
          text: root.adapter ? "Bluetooth is off" : "No adapter"
          color: "#6c7086"
          font.pixelSize: 12
        }
      }

      ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(360, contentHeight)
        clip: true
        visible: root.adapter && root.adapter.enabled
        spacing: 2

        model: {
          var rows = [];
          if (root.connectedDevices.length > 0)
            rows.push({
              "header": "CONNECTED"
            });
          for (var i = 0; i < root.connectedDevices.length; i++)
            rows.push({
              "device": root.connectedDevices[i]
            });
          if (root.knownDevices.length > 0)
            rows.push({
              "header": "KNOWN"
            });
          for (var j = 0; j < root.knownDevices.length; j++)
            rows.push({
              "device": root.knownDevices[j]
            });
          if (root.adapter && root.adapter.discovering && root.discoveredDevices.length > 0)
            rows.push({
              "header": "NEARBY"
            });
          if (root.adapter && root.adapter.discovering)
            for (var k = 0; k < root.discoveredDevices.length; k++)
              rows.push({
                "device": root.discoveredDevices[k]
              });
          return rows;
        }

        delegate: Item {
          id: rowItem
          required property var modelData
          width: ListView.view.width
          height: modelData.header !== undefined ? 22 : 36

          Text {
            visible: rowItem.modelData.header !== undefined
            text: rowItem.modelData.header || ""
            color: "#6c7086"
            font.pixelSize: 10
            anchors.verticalCenter: parent.verticalCenter
          }

          RowLayout {
            visible: rowItem.modelData.device !== undefined
            anchors.fill: parent

            readonly property var device: rowItem.modelData.device
            readonly property string pending: device ? Model.pendingAction(root.pendingActions, device.address) : ""

            Text {
              text: parent.device && parent.device.connected ? "●" : "○"
              color: parent.device && parent.device.connected ? "#89b4fa" : "#6c7086"
              font.pixelSize: 12
            }

            Text {
              text: parent.device ? Model.deviceLabel(parent.device) : ""
              color: "#cdd6f4"
              font.pixelSize: 13
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Text {
              visible: !!(parent.device && parent.device.batteryAvailable)
              text: parent.device ? Math.round(parent.device.battery * 100) + "%" : ""
              color: "#6c7086"
              font.pixelSize: 11
            }

            Text {
              visible: parent.pending !== ""
              text: parent.pending + "…"
              color: "#89b4fa"
              font.pixelSize: 11
            }

            Text {
              visible: !!(parent.pending === "" && parent.device && (parent.device.paired || parent.device.bonded || parent.device.trusted))
              text: "forget"
              color: "#f38ba8"
              font.pixelSize: 11
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.forgetDevice(parent.parent.device)
              }
            }
          }

          MouseArea {
            visible: rowItem.modelData.device !== undefined
            anchors.fill: parent
            z: -1
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              var device = rowItem.modelData.device;
              if (!device)
                return;
              if (device.connected)
                root.disconnectDevice(device);
              else
                root.connectDevice(device);
            }
          }
        }
      }
    }
  }
}
