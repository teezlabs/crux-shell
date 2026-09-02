import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls
import "NetworkModel.js" as Model

// Wi-Fi network list/connect UI, shared between the wifi popup (PopupHost.qml) and Control Center's inline expand. No window chrome of its own.
ColumnLayout {
  id: root

  // Drives the scanner/polling — true whenever this content is actually
  // on screen, whether that's a standalone popup's visible or a Control
  // Center section's expanded state.
  property bool panelActive: false
  // Emitted when an action should close whatever's hosting this content
  // (e.g. launching the Custom-DNS terminal) — a standalone popup hides
  // itself on this, an inline Control Center section collapses.
  signal requestClose

  spacing: 10

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
      // Custom takes an arbitrary server list on stdin and can't be
      // pre-authorized by sudoers, so it runs in a real terminal that can
      // prompt for both the servers and, if needed, a sudo password.
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
    if (panelActive)
      syncWifiNetworks();
    else
      passwordSsid = "";
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

  RowLayout {
    Layout.fillWidth: true

    Text {
      text: "WI-FI"
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelXsSize
      font.weight: Font.DemiBold
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
      Layout.fillWidth: true
    }

    NToggle {
      checked: Networking.wifiEnabled
      onToggled: root.toggleWifi()
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
      text: "PING"
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelXsSize
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
    }
    Text {
      text: Model.formatPingLatency(root.internetPingLatency, root.internetPingSamples.length > 0)
      color: root.internetPingPacketLoss > 0 ? Color.error : Color.surfaceText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.captionSize
    }
    Text {
      text: "LOSS"
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelXsSize
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
    }
    Text {
      text: Model.formatPacketLoss(root.internetPingPacketLoss, root.internetPingSamples.length > 0)
      color: root.internetPingPacketLoss > 0 ? Color.error : Color.surfaceText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.captionSize
    }

    Text {
      text: "DOWN"
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelXsSize
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
    }
    Text {
      text: root.hasTransferStats ? Model.formatRate(root.downloadRate) : "--"
      color: Color.surfaceText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.captionSize
    }
    Text {
      text: "UP"
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelXsSize
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
    }
    Text {
      text: root.hasTransferStats ? Model.formatRate(root.uploadRate) : "--"
      color: Color.surfaceText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.captionSize
    }

    Text {
      text: "IP"
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelXsSize
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
    }
    Text {
      text: root.info.ip || "--"
      color: Color.surfaceText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.captionSize
    }
    Text {
      text: "GATEWAY"
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelXsSize
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
    }
    Text {
      text: root.info.gateway || "--"
      color: Color.surfaceText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.captionSize
    }
  }

  // ---------------- DNS provider ----------------
  ColumnLayout {
    Layout.fillWidth: true
    spacing: 4

    Text {
      text: "DNS PROVIDER"
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelXsSize
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 4

      Repeater {
        model: root.dnsProviders

        delegate: Item {
          id: dnsPill
          required property string modelData
          readonly property bool selected: root.dnsProvider === modelData
          Layout.fillWidth: true
          height: 24

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: dnsPill.selected ? Color.primaryContainer : Color.surfaceContainer
            strokeColor: dnsPill.selected ? Color.primary : Color.outline
            strokeWidth: Tokens.borderModule
          }

          Text {
            anchors.centerIn: parent
            text: dnsPill.modelData.toUpperCase()
            color: dnsPill.selected ? Color.primaryContainerText : Color.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }

          HoverHandler {
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: root.setDns(dnsPill.modelData)
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

          Rectangle {
            anchors.fill: parent
            color: rowHover.hovered ? Color.surfaceContainerHigh : "transparent"
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4

            Text {
              text: rowItem.modelData.connected ? "●" : (rowItem.modelData.known ? "○" : "·")
              color: rowItem.modelData.connected ? Color.primary : Color.labelText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
            }

            Text {
              text: rowItem.modelData.ssid
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySize
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Text {
              text: rowItem.modelData.signal + "%"
              color: Color.labelText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.captionSize
            }

            // Forget a saved network; only shown for known, non-connected networks (avoids a confusing disconnect+forget).
            Text {
              visible: rowItem.modelData.known && !rowItem.modelData.connected && !(root.actionKind !== "" && root.actionSsid === rowItem.modelData.ssid)
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
                onClicked: root.forgetRow(rowItem.modelData)
              }
            }

            Text {
              visible: root.actionKind !== "" && root.actionSsid === rowItem.modelData.ssid
              text: (root.actionKind === "connect" ? "CONNECTING" : (root.actionKind === "disconnect" ? "DISCONNECTING" : "FORGETTING")) + "…"
              color: Color.primary
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
              font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
            }
          }

          HoverHandler {
            id: rowHover
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: root.activateRow(rowItem.modelData)
          }
        }

        RowLayout {
          visible: rowItem.modelData.ssid === root.passwordSsid
          width: parent.width
          spacing: 6

          Item {
            Layout.fillWidth: true
            height: 24

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferIcon
              cutTopRight: true
              cutBottomLeft: true
              fillColor: Color.surface
              strokeColor: pwInput.activeFocus ? Color.primary : Color.outline
              strokeWidth: Tokens.borderModule
            }

            TextInput {
              id: pwInput
              anchors.fill: parent
              anchors.leftMargin: 6
              anchors.rightMargin: 6
              verticalAlignment: Text.AlignVCenter
              text: root.passwordText
              onTextChanged: root.passwordText = text
              echoMode: TextInput.Password
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.captionSize
              focus: rowItem.modelData.ssid === root.passwordSsid

              Keys.onReturnPressed: root.submitPassword()
            }
          }

          Text {
            text: "CONNECT"
            color: Color.primary
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
            MouseArea {
              anchors.fill: parent
              anchors.margins: -4
              cursorShape: Qt.PointingHandCursor
              onClicked: root.submitPassword()
            }
          }
        }
      }
    }
  }
}
