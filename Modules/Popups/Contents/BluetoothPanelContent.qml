import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import qs.Commons
import qs.Modules.Popups
import qs.Modules.SettingsPanel.Controls
import "BluetoothModel.js" as Model
import qs.Widgets

// Bluetooth page: connected, paired and nearby devices. Shared by the bluetooth popup and the Control Center's sub-page; no window chrome of its own.
ColumnLayout {
  id: root

  // True while this content is on screen, as a popup or inline in Control Center; drives discovery.
  property bool panelActive: false
  // Shown as a Control Center sub-page: the header gets a back arrow.
  property bool showBack: false
  signal backRequested

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
  readonly property bool powered: !!(root.adapter && root.adapter.enabled)
  // The list area scrolls past this height.
  property real maxListHeight: 480

  // BlueZ's icon name (the device class) to a symbol.
  function deviceSymbol(device) {
    const icon = device && device.icon ? device.icon : "";
    if (icon.indexOf("headset") !== -1 || icon.indexOf("headphone") !== -1)
      return "headphones";
    if (icon.indexOf("audio") !== -1 || icon.indexOf("speaker") !== -1)
      return "speaker";
    if (icon.indexOf("mouse") !== -1)
      return "mouse";
    if (icon.indexOf("keyboard") !== -1)
      return "keyboard";
    if (icon.indexOf("gaming") !== -1 || icon.indexOf("joystick") !== -1)
      return "sports_esports";
    if (icon.indexOf("phone") !== -1)
      return "smartphone";
    if (icon.indexOf("computer") !== -1)
      return "computer";
    if (icon.indexOf("video") !== -1 || icon.indexOf("display") !== -1)
      return "tv";
    if (icon.indexOf("watch") !== -1)
      return "watch";
    return "bluetooth";
  }

  function pendingFor(device) {
    return device ? (Model.pendingAction(root.pendingActions, device.address) || root.liveAction(device)) : "";
  }

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
    showBack: root.showBack
    onBackTapped: root.backRequested()
    NToggle {
      checked: root.powered
      enabled: !!root.adapter
      onToggled: root.toggleBluetooth()
    }
  }

  NScrollView {
    id: scroll
    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(cards.implicitHeight, root.maxListHeight)
    contentHeight: cards.implicitHeight

    ColumnLayout {
      id: cards
      width: scroll.width - (scroll.scrollable ? scroll.gutter : 0)
      spacing: Tokens.spaceMd

      NetSection {
        visible: !root.powered

        RowLayout {
          Layout.fillWidth: true
          Layout.margins: Tokens.spaceSm
          spacing: Tokens.spaceMd

          NSymbol {
            name: "bluetooth_disabled"
            size: 22
            color: Colors.labelText
          }
          NText {
            Layout.fillWidth: true
            text: root.adapter ? "Bluetooth is off" : "No Bluetooth adapter"
            size: NText.Size.BodySm
            color: Colors.labelText
          }
          NButton {
            visible: !!root.adapter
            text: "Turn on"
            onClicked: root.toggleBluetooth()
          }
        }
      }

      // ---- Connected ----
      NetSection {
        visible: root.powered && root.connectedDevices.length > 0
        label: "CONNECTED"
        active: true

        Repeater {
          model: root.connectedDevices

          delegate: NetRow {
            required property var modelData
            readonly property string pending: root.pendingFor(modelData)
            symbol: root.deviceSymbol(modelData)
            ring: modelData.batteryAvailable ? Math.round(modelData.battery * 100) : -1
            highlighted: true
            title: Model.deviceLabel(modelData)
            subtitle: pending !== "" ? pending.charAt(0).toUpperCase() + pending.slice(1) + "…" : (modelData.batteryAvailable ? "Connected  ·  " + Math.round(modelData.battery * 100) + "%" : "Connected")
            actions: [
              {
                "label": "Disconnect",
                "symbol": "link_off"
              },
              {
                "label": "Forget",
                "symbol": "delete",
                "tone": "error"
              }
            ]
            onTapped: root.disconnectDevice(modelData)
            onActionTriggered: index => index === 0 ? root.disconnectDevice(modelData) : root.forgetDevice(modelData)
          }
        }
      }

      // ---- Paired ----
      NetSection {
        visible: root.powered && root.knownDevices.length > 0
        label: "PAIRED"

        Repeater {
          model: root.knownDevices

          delegate: NetRow {
            required property var modelData
            readonly property string pending: root.pendingFor(modelData)
            readonly property bool failed: pending === "" && !!root.failedActions[modelData.address]
            symbol: root.deviceSymbol(modelData)
            title: Model.deviceLabel(modelData)
            subtitle: pending !== "" ? pending.charAt(0).toUpperCase() + pending.slice(1) + "…" : (failed ? "Couldn't connect" : "Tap to connect")
            trailingColor: Colors.error
            actions: [
              {
                "label": "Forget",
                "symbol": "delete",
                "tone": "error"
              }
            ]
            onTapped: root.connectDevice(modelData)
            onActionTriggered: root.forgetDevice(modelData)
          }
        }
      }

      // ---- Nearby: only while this page is discovering ----
      NetSection {
        visible: root.powered
        label: "NEARBY"
        trailing: [
          NSymbol {
            name: "progress_activity"
            size: 14
            color: Colors.primary
            visible: !!(root.adapter && root.adapter.discovering)
            RotationAnimation on rotation {
              running: !!(root.adapter && root.adapter.discovering) && root.panelActive
              from: 0
              to: 360
              duration: 1200
              loops: Animation.Infinite
            }
          }
        ]

        NText {
          visible: root.discoveredDevices.length === 0
          Layout.fillWidth: true
          Layout.margins: Tokens.spaceSm
          text: root.adapter && root.adapter.discovering ? "Searching for devices…" : "Not searching"
          size: NText.Size.Caption
          color: Colors.labelText
        }

        Repeater {
          model: root.adapter && root.adapter.discovering ? root.discoveredDevices : []

          delegate: NetRow {
            required property var modelData
            readonly property string pending: root.pendingFor(modelData)
            readonly property bool failed: pending === "" && !!root.failedActions[modelData.address]
            symbol: root.deviceSymbol(modelData)
            title: Model.deviceLabel(modelData)
            subtitle: pending !== "" ? pending.charAt(0).toUpperCase() + pending.slice(1) + "…" : (failed ? "Couldn't pair" : "Tap to pair")
            onTapped: root.connectDevice(modelData)
          }
        }
      }
    }
  }
}
