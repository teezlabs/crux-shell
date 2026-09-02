import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import "BluetoothModel.js" as Model

// Bluetooth device list/pair UI, shared between the bluetooth popup (PopupHost.qml) and Control Center's inline expand. No window chrome of its own.
ColumnLayout {
  id: root

  // Drives discovery/polling — true whenever this content is actually on
  // screen, whether that's a standalone popup's visible or a Control
  // Center section's expanded state.
  property bool panelActive: false

  spacing: 10

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var devices: Bluetooth.devices ? Bluetooth.devices.values : []
  readonly property var deviceGroups: Model.deviceLists(devices, Settings.data.bluetooth.hideUnnamedDevices)
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
    return [root._binDir + "crux-bluetooth-device", action, address];
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
    running: root.panelActive
    onTriggered: root.syncPendingActions()
  }

  function toggleBluetooth() {
    if (!adapter)
      return;
    Quickshell.execDetached([root._binDir + "crux-bluetooth-power", adapter.enabled ? "off" : "on"]);
  }

  // Discovery is a BlueZ session other clients may also hold; only stop it if
  // this panel was the one that started it.
  property bool owesDiscoveryStop: false

  onPanelActiveChanged: {
    if (panelActive) {
      if (adapter && adapter.enabled && !adapter.discovering) {
        adapter.discovering = true;
        owesDiscoveryStop = true;
      }
    } else if (owesDiscoveryStop && adapter && adapter.discovering) {
      adapter.discovering = false;
      owesDiscoveryStop = false;
    }
  }

  RowLayout {
    Layout.fillWidth: true

    Text {
      text: "BLUETOOTH"
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelXsSize
      font.weight: Font.DemiBold
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
      Layout.fillWidth: true
    }

    NToggle {
      checked: !!(root.adapter && root.adapter.enabled)
      onToggled: root.toggleBluetooth()
    }
  }

  Text {
    visible: !root.adapter || !root.adapter.enabled
    text: root.adapter ? "Bluetooth is off" : "No adapter"
    color: Color.labelText
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.bodySmSize
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
        text: (rowItem.modelData.header || "").toUpperCase()
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
        font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        anchors.verticalCenter: parent.verticalCenter
      }

      Rectangle {
        visible: rowItem.modelData.device !== undefined
        anchors.fill: parent
        color: rowHover.hovered ? Color.surfaceContainerHigh : "transparent"
      }

      RowLayout {
        visible: rowItem.modelData.device !== undefined
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 8

        readonly property var device: rowItem.modelData.device
        readonly property string pending: device ? Model.pendingAction(root.pendingActions, device.address) : ""

        Text {
          text: parent.device && parent.device.connected ? "●" : "○"
          color: parent.device && parent.device.connected ? Color.primary : Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
        }

        Text {
          text: parent.device ? Model.deviceLabel(parent.device) : ""
          color: Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySize
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Text {
          visible: !!(parent.device && parent.device.batteryAvailable)
          text: parent.device ? Math.round(parent.device.battery * 100) + "%" : ""
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.captionSize
        }

        Text {
          visible: parent.pending !== ""
          text: parent.pending.toUpperCase() + "…"
          color: Color.primary
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.captionSize
        }

        Text {
          visible: !!(parent.pending === "" && parent.device && (parent.device.paired || parent.device.bonded || parent.device.trusted))
          text: "FORGET"
          color: Color.error
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: root.forgetDevice(parent.parent.device)
          }
        }
      }

      HoverHandler {
        id: rowHover
        enabled: rowItem.modelData.device !== undefined
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
