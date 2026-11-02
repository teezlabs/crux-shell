import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.Commons
import qs.Modules.Popups
import qs.Modules.SettingsPanel.Controls
import "BluetoothModel.js" as Model
import qs.Widgets

// Bluetooth device list/pair UI, shared between the bluetooth popup (PopupHost.qml) and Control Center's inline expand. No window chrome of its own.
ColumnLayout {
  id: root

  // True while this content is on screen, as a popup or inline in Control Center; drives discovery.
  property bool panelActive: false

  spacing: Tokens.spaceLg

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var devices: Bluetooth.devices ? Bluetooth.devices.values : []
  readonly property var deviceGroups: Model.deviceLists(devices, Settings.data.bluetooth.hideUnnamedDevices)
  readonly property var connectedDevices: deviceGroups.connected || []
  readonly property var knownDevices: deviceGroups.known || []
  readonly property var discoveredDevices: deviceGroups.discovered || []

  // address -> "connecting" | "disconnecting" | "forgetting", while crux-bluetooth-device runs
  property var pendingActions: ({})
  // address -> true after a failed action, until the next action on it or the panel closes
  property var failedActions: ({})

  readonly property string _binDir: Quickshell.shellDir + "/bin/"

  // BlueZ's own state covers connects started elsewhere (auto-reconnect, bluetoothctl).
  function liveAction(device) {
    if (!device)
      return "";
    if (device.pairing)
      return "pairing";
    if (device.state === BluetoothDeviceState.Connecting)
      return "connecting";
    if (device.state === BluetoothDeviceState.Disconnecting)
      return "disconnecting";
    return "";
  }

  Component {
    id: actionProcComponent
    Process {
      property string address
      onExited: function (exitCode) {
        root.pendingActions = Model.withPendingAction(root.pendingActions, address, "");
        if (exitCode !== 0)
          root.failedActions = Model.withPendingAction(root.failedActions, address, true);
        destroy();
      }
    }
  }

  function runDeviceAction(device, action, pending) {
    if (!device || !device.address || pendingActions[device.address])
      return;
    pendingActions = Model.withPendingAction(pendingActions, device.address, pending);
    failedActions = Model.withPendingAction(failedActions, device.address, false);
    var proc = actionProcComponent.createObject(root, {
      "address": device.address,
      "command": [root._binDir + "crux-bluetooth-device", action, device.address]
    });
    proc.running = true;
  }

  function connectDevice(device) {
    if (!device || device.connected)
      return;
    runDeviceAction(device, (device.paired || device.bonded || device.trusted) ? "connect" : "pair", "connecting");
  }

  function disconnectDevice(device) {
    if (!device || !device.connected)
      return;
    runDeviceAction(device, "disconnect", "disconnecting");
  }

  function forgetDevice(device) {
    runDeviceAction(device, "forget", "forgetting");
  }

  function toggleBluetooth() {
    if (!adapter)
      return;
    Quickshell.execDetached([root._binDir + "crux-bluetooth-power", adapter.enabled ? "off" : "on"]);
  }

  // Other clients may hold the discovery session, so only stop discovery this panel started.
  property bool owesDiscoveryStop: false

  function updateDiscovery() {
    if (panelActive && adapter && adapter.enabled) {
      if (!adapter.discovering) {
        adapter.discovering = true;
        owesDiscoveryStop = true;
      }
    } else if (owesDiscoveryStop) {
      if (adapter && adapter.discovering)
        adapter.discovering = false;
      owesDiscoveryStop = false;
    }
  }

  onPanelActiveChanged: {
    updateDiscovery();
    if (!panelActive)
      failedActions = ({});
  }

  Connections {
    target: root.adapter
    function onEnabledChanged() {
      root.updateDiscovery();
    }
  }

  PopupHeader {
    title: "BLUETOOTH"
    NToggle {
      checked: !!(root.adapter && root.adapter.enabled)
      onToggled: root.toggleBluetooth()
    }
  }

  NText {
    visible: !root.adapter || !root.adapter.enabled
    text: root.adapter ? "Bluetooth is off" : "No adapter"
    color: Colors.labelText
    size: NText.Size.BodySm
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
      height: modelData.header !== undefined ? 22 : Tokens.rowHeight

      NText {
        tracking: true
        visible: rowItem.modelData.header !== undefined
        text: (rowItem.modelData.header || "").toUpperCase()
        color: Colors.labelText
        size: NText.Size.LabelXs
        anchors.verticalCenter: parent.verticalCenter
      }

      PopupRowBackground {
        visible: rowItem.modelData.device !== undefined
        hovered: rowHover.hovered
        selected: !!(rowItem.modelData.device && rowItem.modelData.device.connected)
      }

      RowLayout {
        visible: rowItem.modelData.device !== undefined
        anchors.fill: parent
        anchors.leftMargin: Tokens.spaceMd
        anchors.rightMargin: Tokens.spaceMd
        spacing: 8

        readonly property var device: rowItem.modelData.device
        readonly property string pending: device ? (Model.pendingAction(root.pendingActions, device.address) || root.liveAction(device)) : ""
        readonly property bool failed: !!(device && pending === "" && root.failedActions[device.address])

        NText {
          text: parent.device && parent.device.connected ? "●" : "○"
          color: parent.device && parent.device.connected ? Colors.primary : Colors.labelText
          size: NText.Size.BodySm
        }

        NText {
          text: parent.device ? Model.deviceLabel(parent.device) : ""
          color: Colors.surfaceText
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        NText {
          visible: !!(parent.device && parent.device.batteryAvailable)
          text: parent.device ? Math.round(parent.device.battery * 100) + "%" : ""
          color: Colors.labelText
          size: NText.Size.Caption
        }

        NText {
          tracking: true
          visible: parent.failed
          text: "FAILED"
          color: Colors.error
          size: NText.Size.LabelXs
        }

        NText {
          visible: parent.pending !== ""
          text: parent.pending.toUpperCase() + "…"
          color: Colors.primary
          size: NText.Size.Caption
        }

        NText {
          tracking: true
          visible: !!(parent.pending === "" && parent.device && (parent.device.paired || parent.device.bonded || parent.device.trusted))
          text: "FORGET"
          color: Colors.error
          size: NText.Size.LabelXs
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
