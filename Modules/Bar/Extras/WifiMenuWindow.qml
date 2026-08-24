import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Networking
import "NetworkModel.js" as Model

// Wi-Fi popup: real data/behavior ported from Omarchy's
// shell/plugins/panels/network Panel.qml + Model.js (same Quickshell.Networking
// backend, same connect/disconnect/forget/sort logic) — UI rebuilt on crux's
// own lean primitives instead of importing Omarchy's shared Ui kit.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property var networkDevices: Networking.devices ? Networking.devices.values : []
  readonly property var wifiDevice: findDevice(DeviceType.Wifi)
  readonly property var wifiNetworkObjects: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : []
  property var wifiNetworks: []

  property string actionSsid: ""
  property string actionKind: "" // "connect" | "disconnect" | "forget"
  readonly property bool busy: actionKind !== ""

  property string passwordSsid: ""
  property string passwordText: ""
  property string failureSsid: ""
  property string failureReason: ""

  readonly property string _binDir: Quickshell.env("HOME") + "/.config/quickshell/crux/bin/"

  // ---------------- Connection details (ported from Omarchy's Panel.qml) ----------------
  property var info: ({})
  property real prevRxBytes: 0
  property real prevTxBytes: 0
  property real prevSampleTime: 0
  property string prevIface: ""
  property real downloadRate: 0
  property real uploadRate: 0
  property string pingIface: ""
  property var routerPingSamples: []
  property var internetPingSamples: []
  property real internetPingLatency: -1
  property int internetPingPacketLoss: 0
  readonly property bool hasTransferStats: info.rx_bytes !== undefined

  function updateDetails(raw) {
    var next = Model.parseKeyValue(raw);
    info = next;
    var t = Model.throughputState({
      "prevIface": prevIface,
      "prevRxBytes": prevRxBytes,
      "prevTxBytes": prevTxBytes,
      "prevSampleTime": prevSampleTime,
      "downloadRate": downloadRate,
      "uploadRate": uploadRate
    }, next, Date.now() / 1000);
    prevIface = t.prevIface;
    prevRxBytes = t.prevRxBytes;
    prevTxBytes = t.prevTxBytes;
    prevSampleTime = t.prevSampleTime;
    downloadRate = t.downloadRate;
    uploadRate = t.uploadRate;

    var p = Model.pingLatencyState({
      "pingIface": pingIface,
      "routerPingSamples": routerPingSamples,
      "internetPingSamples": internetPingSamples
    }, next, 24, 5);
    pingIface = p.pingIface;
    routerPingSamples = p.routerPingSamples;
    internetPingSamples = p.internetPingSamples;
    internetPingLatency = p.internetPingLatency;
    internetPingPacketLoss = p.internetPingPacketLoss;
  }

  Process {
    id: detailsProc
    command: [root._binDir + "omarchy-network-status", "--verbose"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateDetails(text)
    }
  }

  Timer {
    interval: 1500
    repeat: true
    running: root.visible
    triggeredOnStart: true
    onTriggered: if (!detailsProc.running)
      detailsProc.running = true
  }

  // ---------------- DNS provider ----------------
  property string dnsProvider: "DHCP"
  readonly property var dnsProviders: ["DHCP", "Cloudflare", "Google", "Custom"]
  property string customDnsText: ""

  Process {
    id: dnsProc
    command: ["omarchy-dns"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.dnsProvider = text.trim() || "DHCP"
    }
  }

  Process {
    id: dnsActionProc
    onExited: function (exitCode) {
      if (!dnsProc.running)
        dnsProc.running = true;
    }
  }

  function setDns(provider) {
    if (dnsActionProc.running)
      return;
    if (provider === "Custom") {
      // Custom takes an arbitrary server list on stdin and can't be
      // pre-authorized by sudoers, so — same as Omarchy's own panel — it
      // runs in a real terminal that can prompt for both the servers and,
      // if needed, a sudo password.
      Quickshell.execDetached(["kitty", "--", "bash", "-c", "omarchy-dns Custom; read -p 'Press enter to close...'"]);
      root.visible = false;
      return;
    }
    dnsActionProc.command = ["omarchy-dns", provider];
    dnsActionProc.running = true;
  }

  Component.onCompleted: {
    dnsProc.running = true;
  }

  function findDevice(type) {
    var devices = networkDevices || [];
    for (var i = 0; i < devices.length; i++) {
      if (devices[i] && devices[i].type === type)
        return devices[i];
    }
    return null;
  }

  function networkForSsid(ssid) {
    var networks = wifiNetworkObjects || [];
    for (var i = 0; i < networks.length; i++) {
      if (networks[i] && networks[i].name === ssid)
        return networks[i];
    }
    return null;
  }

  function requiresCredentials(security) {
    return Model.requiresCredentials(security, WifiSecurityType.Open, WifiSecurityType.Owe);
  }

  function syncWifiNetworks() {
    var nets = [];
    var networks = wifiNetworkObjects || [];
    for (var i = 0; i < networks.length; i++) {
      var network = networks[i];
      if (!network)
        continue;
      checkActionCompletion(network);
      var row = Model.wifiRow(network);
      if (row)
        nets.push(row);
    }
    wifiNetworks = Model.sortWifiRows(nets);
  }

  function checkActionCompletion(network) {
    if (!network || actionKind === "" || actionSsid !== (network.name || ""))
      return;
    if (actionKind === "connect" && network.connected)
      clearAction();
    else if (actionKind === "disconnect" && !network.connected && !network.stateChanging)
      clearAction();
    else if (actionKind === "forget" && !network.known && !network.stateChanging)
      clearAction();
  }

  function clearAction() {
    if (actionKind === "connect")
      passwordSsid = "";
    failureSsid = "";
    failureReason = "";
    actionSsid = "";
    actionKind = "";
  }

  function runAction(kind, network, callback) {
    if (actionKind !== "" || !network)
      return;
    actionSsid = network.name || "";
    actionKind = kind;
    failureSsid = "";
    failureReason = "";
    callback(network);
  }

  function activateRow(row) {
    if (busy)
      return;
    var network = networkForSsid(row.ssid);
    if (!network)
      return;
    if (row.connected) {
      runAction("disconnect", network, function (n) {
        n.disconnect();
      });
      return;
    }
    if (requiresCredentials(row.security) && !row.known) {
      passwordSsid = row.ssid;
      passwordText = "";
      return;
    }
    runAction("connect", network, function (n) {
      n.connect();
    });
  }

  function submitPassword() {
    var network = networkForSsid(passwordSsid);
    if (!network || passwordText === "")
      return;
    runAction("connect", network, function (n) {
      n.connectWithPsk(passwordText);
    });
  }

  function forgetRow(row) {
    var network = networkForSsid(row.ssid);
    runAction("forget", network, function (n) {
      n.forget();
    });
  }

  function toggleWifi() {
    Networking.wifiEnabled = !Networking.wifiEnabled;
    Qt.callLater(function () {
      root.syncWifiNetworks();
    });
  }

  // Nearby (unconnected) networks only show up once the device's scanner is
  // switched on — Quickshell.Networking doesn't scan passively. scannerEnabled
  // lives on the shared WifiDevice with no ref-counting, so track which device
  // this popup turned it on for and release exactly that one on close.
  property var scannerDevice: null

  function setScannerEnabled(enabled) {
    var nextDevice = visible ? wifiDevice : null;
    if (scannerDevice && scannerDevice !== nextDevice)
      scannerDevice.scannerEnabled = false;
    scannerDevice = nextDevice;
    if (scannerDevice)
      scannerDevice.scannerEnabled = enabled;
  }

  Component.onDestruction: {
    if (scannerDevice)
      scannerDevice.scannerEnabled = false;
  }

  onVisibleChanged: setScannerEnabled(true)
  onWifiDeviceChanged: setScannerEnabled(true)

  Timer {
    id: scanRefresh
    interval: 1500
    repeat: true
    running: root.visible
    onTriggered: root.syncWifiNetworks()
  }

  onWifiNetworkObjectsChanged: syncWifiNetworks()

  visible: false
  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-wifi-menu"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  function toggle() {
    visible = !visible;
    if (visible)
      syncWifiNetworks();
    else
      passwordSsid = "";
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
    width: 360
    height: Math.min(560, column.implicitHeight + 24)
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
          text: "Wi-Fi"
          color: "#cdd6f4"
          font.pixelSize: 14
          font.bold: true
          Layout.fillWidth: true
        }

        Rectangle {
          width: 36
          height: 18
          radius: 2
          color: Networking.wifiEnabled ? "#89b4fa" : "#45475a"

          Rectangle {
            width: 14
            height: 14
            radius: 1
            color: "#1e1e2e"
            anchors.verticalCenter: parent.verticalCenter
            x: Networking.wifiEnabled ? parent.width - width - 2 : 2
            Behavior on x {
              NumberAnimation {
                duration: 120
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleWifi()
          }
        }
      }

      // ---------------- Connection details ----------------
      GridLayout {
        Layout.fillWidth: true
        visible: !!root.info.iface
        columns: 4
        columnSpacing: 14
        rowSpacing: 4

        Text {
          text: "Ping"
          color: "#6c7086"
          font.pixelSize: 10
        }
        Text {
          text: Model.formatPingLatency(root.internetPingLatency, root.internetPingSamples.length > 0)
          color: root.internetPingPacketLoss > 0 ? "#f38ba8" : "#cdd6f4"
          font.pixelSize: 11
        }
        Text {
          text: "Loss"
          color: "#6c7086"
          font.pixelSize: 10
        }
        Text {
          text: Model.formatPacketLoss(root.internetPingPacketLoss, root.internetPingSamples.length > 0)
          color: root.internetPingPacketLoss > 0 ? "#f38ba8" : "#cdd6f4"
          font.pixelSize: 11
        }

        Text {
          text: "Down"
          color: "#6c7086"
          font.pixelSize: 10
        }
        Text {
          text: root.hasTransferStats ? Model.formatRate(root.downloadRate) : "--"
          color: "#cdd6f4"
          font.pixelSize: 11
        }
        Text {
          text: "Up"
          color: "#6c7086"
          font.pixelSize: 10
        }
        Text {
          text: root.hasTransferStats ? Model.formatRate(root.uploadRate) : "--"
          color: "#cdd6f4"
          font.pixelSize: 11
        }

        Text {
          text: "IP"
          color: "#6c7086"
          font.pixelSize: 10
        }
        Text {
          text: root.info.ip || "--"
          color: "#cdd6f4"
          font.pixelSize: 11
        }
        Text {
          text: "Gateway"
          color: "#6c7086"
          font.pixelSize: 10
        }
        Text {
          text: root.info.gateway || "--"
          color: "#cdd6f4"
          font.pixelSize: 11
        }
      }

      // ---------------- DNS provider ----------------
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Text {
          text: "DNS PROVIDER"
          color: "#6c7086"
          font.pixelSize: 10
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 4

          Repeater {
            model: root.dnsProviders

            delegate: Rectangle {
              required property string modelData
              readonly property bool selected: root.dnsProvider === modelData
              Layout.fillWidth: true
              height: 24
              radius: 1
              color: selected ? "#89b4fa" : "#313244"

              Text {
                anchors.centerIn: parent
                text: parent.modelData
                color: parent.selected ? "#1e1e2e" : "#cdd6f4"
                font.pixelSize: 11
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.setDns(parent.modelData)
              }
            }
          }
        }
      }

      ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(320, contentHeight)
        clip: true
        visible: Networking.wifiEnabled
        model: root.wifiNetworks

        delegate: Item {
          id: rowItem
          required property var modelData
          required property int index
          width: ListView.view.width
          height: rowItem.modelData.ssid === root.passwordSsid ? 76 : 36

          Column {
            anchors.fill: parent
            spacing: 4

            Item {
              width: parent.width
              height: 36

              RowLayout {
                anchors.fill: parent

                Text {
                  text: rowItem.modelData.connected ? "●" : (rowItem.modelData.known ? "○" : "·")
                  color: rowItem.modelData.connected ? "#89b4fa" : "#6c7086"
                  font.pixelSize: 12
                }

                Text {
                  text: rowItem.modelData.ssid
                  color: "#cdd6f4"
                  font.pixelSize: 13
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }

                Text {
                  text: rowItem.modelData.signal + "%"
                  color: "#6c7086"
                  font.pixelSize: 11
                }

                Text {
                  visible: root.actionKind !== "" && root.actionSsid === rowItem.modelData.ssid
                  text: root.actionKind === "connect" ? "connecting…" : (root.actionKind === "disconnect" ? "disconnecting…" : "forgetting…")
                  color: "#89b4fa"
                  font.pixelSize: 11
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activateRow(rowItem.modelData)
              }
            }

            RowLayout {
              visible: rowItem.modelData.ssid === root.passwordSsid
              width: parent.width
              spacing: 6

              TextInput {
                Layout.fillWidth: true
                text: root.passwordText
                onTextChanged: root.passwordText = text
                echoMode: TextInput.Password
                color: "#cdd6f4"
                font.pixelSize: 12
                focus: rowItem.modelData.ssid === root.passwordSsid

                Rectangle {
                  z: -1
                  anchors.fill: parent
                  anchors.margins: -4
                  color: "#313244"
                  radius: 1
                }

                Keys.onReturnPressed: root.submitPassword()
              }

              Text {
                text: "Connect"
                color: "#89b4fa"
                font.pixelSize: 12
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.submitPassword()
                }
              }
            }
          }
        }
      }
    }
  }
}
