import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras

// VPN connection status/toggle, NetworkManager-based (same `nmcli`
// primitive noctalia-shell's VPNService.qml uses: `connection show` for
// status — TYPE filtered to "vpn"/"wireguard" only, since nmcli lists every
// connection profile including plain wifi/ethernet/loopback/bridges — and
// `connection up/down uuid <uuid>` to toggle). Left-click toggles the first
// connection (connects if none active, disconnects if one is); the full
// multi-connection list lives in Settings > Peripherals for boxes with more
// than one VPN profile.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  // uuid -> {uuid, name, device, active}
  property var connections: ({})
  property bool busy: false

  readonly property var connectionList: {
    var list = [];
    for (var uuid in root.connections)
      list.push(root.connections[uuid]);
    return list;
  }
  readonly property var activeConnection: {
    for (var i = 0; i < connectionList.length; i++) {
      if (connectionList[i].active)
        return connectionList[i];
    }
    return null;
  }
  readonly property bool hasVpn: connectionList.length > 0
  readonly property bool connected: !!activeConnection

  visible: hasVpn
  implicitWidth: visible ? btn.implicitWidth : 0
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  Process {
    id: refreshProc
    command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,DEVICE", "connection", "show"]
    stdout: StdioCollector {
      onStreamFinished: {
        var map = {};
        var lines = text.split("\n");
        for (var i = 0; i < lines.length; i++) {
          var line = lines[i].trim();
          if (!line)
            continue;
          // nmcli -t fields are colon-separated but a connection NAME can
          // itself contain colons, so parse from the right (same approach
          // noctalia-shell's VPNService.qml uses): DEVICE, then TYPE, then
          // UUID, leaving NAME as whatever remains.
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
        root.connections = map;
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!refreshProc.running)
      refreshProc.running = true
  }

  Process {
    id: toggleProc
    property string mode: "up" // "up" | "down"
    property string uuid: ""
    command: ["nmcli", "connection", mode, "uuid", uuid]
    stdout: StdioCollector {
      onStreamFinished: {
        root.busy = false;
        refreshProc.running = true;
      }
    }
    stderr: StdioCollector {
      onStreamFinished: root.busy = false
    }
  }

  function toggle() {
    if (root.busy || connectionList.length === 0)
      return;
    root.busy = true;
    if (root.activeConnection) {
      toggleProc.mode = "down";
      toggleProc.uuid = root.activeConnection.uuid;
    } else {
      toggleProc.mode = "up";
      toggleProc.uuid = connectionList[0].uuid;
    }
    toggleProc.running = true;
  }

  BarIconButton {
    id: btn
    attention: root.connected
    onTapped: root.toggle()

    HoverHandler {
      id: hoverHandler
      cursorShape: Qt.PointingHandCursor
      onHoveredChanged: {
        if (hovered) {
          var msg = root.activeConnection ? "VPN: " + root.activeConnection.name + " (connected)" : (root.connectionList.length > 0 ? "VPN: disconnected — click to connect " + root.connectionList[0].name : "No VPN connections");
          TooltipService.show(root, msg);
        } else {
          TooltipService.hide();
        }
      }
    }

    // Shield glyph: filled + when connected, outline only when disconnected
    // — no font/emoji glyph dependency.
    Canvas {
      id: canvas
      anchors.centerIn: parent
      width: 14
      height: 16
      readonly property color drawColor: root.connected ? Color.primary : Color.surfaceTextMuted
      readonly property bool filled: root.connected
      readonly property bool isBusy: root.busy
      onDrawColorChanged: requestPaint()
      onFilledChanged: requestPaint()
      onIsBusyChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = drawColor;
        ctx.fillStyle = drawColor;
        ctx.lineWidth = 1.4;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        ctx.beginPath();
        ctx.moveTo(width / 2, 0);
        ctx.lineTo(width, 3);
        ctx.lineTo(width, 8);
        ctx.quadraticCurveTo(width, 13.5, width / 2, 16);
        ctx.quadraticCurveTo(0, 13.5, 0, 8);
        ctx.lineTo(0, 3);
        ctx.closePath();

        if (filled) {
          ctx.globalAlpha = isBusy ? 0.5 : 1.0;
          ctx.fill();
          ctx.globalAlpha = 1.0;
        } else {
          ctx.stroke();
        }
      }
    }
  }
}
