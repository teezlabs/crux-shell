import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.Commons
import qs.Modules.Popups
import qs.Modules.SettingsPanel.Controls
import "NetworkModel.js" as Model
import qs.Widgets

// Network page: the wired connection, Wi-Fi and its networks, DNS. Shared by the wifi popup and the Control Center's sub-page; no window chrome of its own.
ColumnLayout {
  id: root

  // True while this content is on screen, as a popup or inline in Control Center; drives scanning and polling.
  property bool panelActive: false
  // Shown as a Control Center sub-page: the header gets a back arrow.
  property bool showBack: false
  signal backRequested
  // Asks the host to close: a popup hides, the Control Center goes back to its main page.
  signal requestClose

  spacing: Tokens.spaceLg

  readonly property var networkDevices: Networking.devices ? Networking.devices.values : []
  readonly property var wifiDevice: findDevice(DeviceType.Wifi)
  readonly property var wifiNetworkObjects: wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : []
  property var wifiNetworks: []

  property string actionSsid: ""
  property string actionKind: "" // "connect" | "disconnect" | "forget"
  property var actionNetwork: null
  readonly property bool busy: actionKind !== ""

  property string passwordSsid: ""
  property string passwordText: ""
  property string failureSsid: ""
  property string failureReason: ""

  readonly property string _binDir: Quickshell.shellDir + "/bin/"

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
  readonly property bool isWired: info.type === "ethernet"
  readonly property string linkSpeed: {
    const mbps = parseInt(root.info.speed || "", 10);
    if (!mbps || mbps < 0)
      return "";
    return mbps >= 1000 ? (mbps / 1000) + " Gbit/s" : mbps + " Mbit/s";
  }
  readonly property var connectedRows: wifiNetworks.filter(r => r.connected)
  readonly property var otherRows: wifiNetworks.filter(r => !r.connected)
  // The list area scrolls past this height.
  property real maxListHeight: 480

  function copyIp() {
    if (!root.info.ip)
      return;
    Quickshell.clipboardText = root.info.ip;
    Toast.show("Copied " + root.info.ip, 2000);
  }

  function signalSymbol(signal) {
    if (signal >= 75)
      return "signal_wifi_4_bar";
    if (signal >= 50)
      return "network_wifi_3_bar";
    if (signal >= 25)
      return "network_wifi_2_bar";
    return "network_wifi_1_bar";
  }

  function rowStatus(row) {
    if (root.actionKind !== "" && root.actionSsid === row.ssid)
      return (root.actionKind === "connect" ? "Connecting" : (root.actionKind === "disconnect" ? "Disconnecting" : "Forgetting")) + "…";
    if (root.failureSsid !== "" && root.failureSsid === row.ssid)
      return root.failureReason;
    return "";
  }

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
    command: [root._binDir + "crux-network-status", "--verbose"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.updateDetails(text)
    }
  }

  Timer {
    interval: 1500
    repeat: true
    running: root.panelActive
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
    command: ["crux-dns"]
    stdout: StdioCollector {
      id: dnsCollector
      waitForEnd: true
      onStreamFinished: root.dnsProvider = dnsCollector.text.trim() || "DHCP"
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
      // Custom can't be pre-authorized in sudoers, so it runs in a terminal that can prompt.
      Quickshell.execDetached(["kitty", "--", "bash", "-c", "crux-dns Custom; read -p 'Press enter to close...'"]);
      root.requestClose();
      return;
    }
    dnsActionProc.command = ["crux-dns", provider];
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
    actionNetwork = null;
  }

  function failAction(reason) {
    var ssid = actionSsid;
    actionSsid = "";
    actionKind = "";
    actionNetwork = null;
    failureSsid = ssid;
    failureReason = reason;
  }

  function runAction(kind, network, callback) {
    if (actionKind !== "" || !network)
      return;
    actionSsid = network.name || "";
    actionKind = kind;
    actionNetwork = network;
    failureSsid = "";
    failureReason = "";
    callback(network);
  }

  Connections {
    target: root.actionNetwork
    ignoreUnknownSignals: true
    function onConnectionFailed(reason) {
      var network = root.actionNetwork;
      var credentialed = root.requiresCredentials(network.security);
      var ssid = root.actionSsid;
      root.failAction(Model.networkFailureReason(reason, credentialed, ConnectionFailReason));
      if (Model.shouldRepromptPassphrase(reason, credentialed, ConnectionFailReason)) {
        root.passwordSsid = ssid;
        root.passwordText = "";
      }
    }
  }

  // Backstop for a request NetworkManager never answers.
  Timer {
    interval: 30000
    running: root.busy
    onTriggered: root.failAction("Timed out")
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

  // scannerEnabled lives on the shared WifiDevice with no ref-counting — track which device we enabled it on.
  property var scannerDevice: null

  function setScannerEnabled(enabled) {
    var nextDevice = panelActive ? wifiDevice : null;
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

  onPanelActiveChanged: {
    setScannerEnabled(true);
    if (panelActive) {
      syncWifiNetworks();
    } else {
      passwordSsid = "";
      failureSsid = "";
      failureReason = "";
    }
  }
  onWifiDeviceChanged: setScannerEnabled(true)

  Timer {
    id: scanRefresh
    interval: 1500
    repeat: true
    running: root.panelActive
    onTriggered: root.syncWifiNetworks()
  }

  onWifiNetworkObjectsChanged: syncWifiNetworks()

  // Ping, throughput and loss for the live connection, on one line.
  component StatsLine: RowLayout {
    Layout.fillWidth: true
    Layout.leftMargin: Tokens.spaceSm
    Layout.topMargin: Tokens.spaceXs
    spacing: Tokens.spaceSm

    NSymbol {
      name: "speed"
      size: 14
      color: Colors.labelText
    }
    NText {
      text: Model.formatPingLatency(root.internetPingLatency, root.internetPingSamples.length > 0)
      size: NText.Size.Caption
      color: root.internetPingPacketLoss > 0 ? Colors.error : Colors.surfaceText
    }
    NText {
      visible: root.internetPingPacketLoss > 0
      text: Model.formatPacketLoss(root.internetPingPacketLoss, true) + " loss"
      size: NText.Size.Caption
      color: Colors.error
    }
    NSymbol {
      Layout.leftMargin: Tokens.spaceSm
      name: "arrow_downward"
      size: 14
      color: Colors.labelText
    }
    NText {
      text: root.hasTransferStats ? Model.formatRate(root.downloadRate) : "--"
      size: NText.Size.Caption
    }
    NSymbol {
      Layout.leftMargin: Tokens.spaceSm
      name: "arrow_upward"
      size: 14
      color: Colors.labelText
    }
    NText {
      Layout.fillWidth: true
      text: root.hasTransferStats ? Model.formatRate(root.uploadRate) : "--"
      size: NText.Size.Caption
    }
  }

  // DNS provider for the live connection.
  component DnsSwitch: ColumnLayout {
    Layout.fillWidth: true
    Layout.leftMargin: Tokens.spaceSm
    Layout.topMargin: Tokens.spaceSm
    spacing: Tokens.spaceXs

    NText {
      text: "DNS"
      tracking: true
      size: NText.Size.LabelXs
      font.weight: Font.DemiBold
      color: Colors.labelText
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Tokens.spaceXs

      Repeater {
        model: root.dnsProviders

        delegate: Item {
          id: dnsPill
          required property string modelData
          readonly property bool selected: root.dnsProvider === modelData
          Layout.fillWidth: true
          implicitHeight: 24

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: dnsPill.selected ? Colors.primaryContainer : (dnsHover.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainerLow)
            strokeColor: dnsPill.selected ? Colors.primary : Colors.outlineVariant
            strokeWidth: Tokens.borderModule
          }
          NText {
            anchors.centerIn: parent
            text: dnsPill.modelData.toUpperCase()
            tracking: true
            size: NText.Size.LabelXs
            color: dnsPill.selected ? Colors.primaryContainerText : Colors.surfaceText
          }
          HoverHandler {
            id: dnsHover
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: root.setDns(dnsPill.modelData)
          }
        }
      }
    }
  }

  PopupHeader {
    title: root.passwordSsid !== "" ? "JOIN NETWORK" : "NETWORK"
    showBack: root.showBack || root.passwordSsid !== ""
    onBackTapped: {
      if (root.passwordSsid !== "") {
        root.passwordSsid = "";
        root.passwordText = "";
      } else {
        root.backRequested();
      }
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

      // ---- Password for a secured network: replaces the lists until it connects or is cancelled ----
      NetSection {
        visible: root.passwordSsid !== ""
        label: root.passwordSsid

        RowLayout {
          Layout.fillWidth: true
          Layout.margins: Tokens.spaceXs
          spacing: Tokens.spaceSm

          Item {
            Layout.fillWidth: true
            implicitHeight: 32

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: Colors.surface
              strokeColor: pwInput.activeFocus ? Colors.primary : Colors.outline
              strokeWidth: Tokens.borderModule
            }
            TextInput {
              id: pwInput
              anchors.fill: parent
              anchors.leftMargin: Tokens.spaceMd
              anchors.rightMargin: Tokens.spaceMd
              verticalAlignment: Text.AlignVCenter
              text: root.passwordText
              onTextChanged: root.passwordText = text
              echoMode: TextInput.Password
              color: Colors.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
              clip: true
              Keys.onReturnPressed: root.submitPassword()
              Keys.onEnterPressed: root.submitPassword()

              NText {
                anchors.fill: parent
                visible: pwInput.text === ""
                text: "Password"
                size: NText.Size.BodySm
                color: Colors.labelText
              }
            }
          }

          NButton {
            text: root.actionKind === "connect" ? "…" : "Connect"
            enabled: root.passwordText !== "" && root.actionKind === ""
            onClicked: root.submitPassword()
          }
        }

        NText {
          Layout.fillWidth: true
          Layout.leftMargin: Tokens.spaceXs
          visible: text !== ""
          text: root.failureSsid === root.passwordSsid ? root.failureReason : ""
          size: NText.Size.Caption
          color: Colors.error
        }
      }

      // ---- Wired ----
      NetSection {
        visible: root.passwordSsid === "" && root.isWired
        label: "ETHERNET"
        active: true

        NetRow {
          symbol: "lan"
          highlighted: true
          interactive: false
          title: root.info.iface || "Ethernet"
          subtitle: (root.info.ip || "No address") + (root.linkSpeed !== "" ? "  ·  " + root.linkSpeed : "")
          actions: [
            {
              "label": "Copy IP",
              "symbol": "content_copy"
            }
          ]
          onActionTriggered: root.copyIp()
        }
        StatsLine {}
        DnsSwitch {}
      }

      // ---- Wi-Fi ----
      NetSection {
        visible: root.passwordSsid === ""
        label: "WI-FI"
        active: !root.isWired && root.connectedRows.length > 0
        trailing: [
          NToggle {
            checked: Networking.wifiEnabled
            enabled: Networking.wifiHardwareEnabled
            onToggled: root.toggleWifi()
          }
        ]

        NText {
          visible: !Networking.wifiEnabled || !root.wifiDevice || root.wifiNetworks.length === 0
          Layout.fillWidth: true
          Layout.margins: Tokens.spaceSm
          text: !Networking.wifiHardwareEnabled ? "Blocked by a hardware switch" : (!root.wifiDevice ? "No Wi-Fi adapter" : (!Networking.wifiEnabled ? (root.isWired ? "Off. You're on the cable." : "Off") : "Scanning…"))
          size: NText.Size.BodySm
          color: Colors.labelText
        }

        Repeater {
          model: Networking.wifiEnabled ? root.connectedRows : []

          delegate: NetRow {
            required property var modelData
            symbol: root.signalSymbol(modelData.signal)
            ring: modelData.signal
            highlighted: true
            title: modelData.ssid
            subtitle: root.rowStatus(modelData) || "Connected" + (root.isWired ? "" : (root.info.ip ? "  ·  " + root.info.ip : ""))
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
            onTapped: root.activateRow(modelData)
            onActionTriggered: index => index === 0 ? root.activateRow(modelData) : root.forgetRow(modelData)
          }
        }

        StatsLine {
          visible: !root.isWired && root.connectedRows.length > 0
        }
        DnsSwitch {
          visible: !root.isWired && root.connectedRows.length > 0
        }
      }

      // ---- Other networks ----
      NetSection {
        visible: root.passwordSsid === "" && Networking.wifiEnabled && root.otherRows.length > 0
        label: "NETWORKS"

        Repeater {
          model: root.otherRows

          delegate: NetRow {
            required property var modelData
            readonly property string status: root.rowStatus(modelData)
            symbol: root.signalSymbol(modelData.signal)
            ring: modelData.signal
            title: modelData.ssid
            subtitle: modelData.known ? "Saved" : (root.requiresCredentials(modelData.security) ? "Secured" : "Open")
            trailing: status
            trailingColor: root.failureSsid === modelData.ssid ? Colors.error : Colors.primary
            locked: root.requiresCredentials(modelData.security) && !modelData.known
            actions: modelData.known ? [
              {
                "label": "Forget",
                "symbol": "delete",
                "tone": "error"
              }
            ] : []
            onTapped: root.activateRow(modelData)
            onActionTriggered: root.forgetRow(modelData)
          }
        }
      }
    }
  }

  onPasswordSsidChanged: if (root.passwordSsid !== "")
    Qt.callLater(() => pwInput.forceActiveFocus())
}
