import QtQuick
import qs.Commons
import qs.Services
import qs.Modules.Bar.Extras

// VPN status from NetworkManager; click toggles the first connection. The full list is in Settings > Peripherals.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool invertChamfer: false

  readonly property var connectionList: NetworkManager.vpnConnections
  readonly property var activeConnection: NetworkManager.activeVpn
  readonly property bool busy: NetworkManager.busy
  readonly property bool hasVpn: connectionList.length > 0
  readonly property bool connected: !!activeConnection

  visible: hasVpn
  implicitWidth: visible ? btn.implicitWidth : 0
  implicitHeight: Tokens.barCell
  width: implicitWidth
  height: implicitHeight

  BarIconButton {
    id: btn
    invertChamfer: root.invertChamfer
    onTapped: NetworkManager.toggleVpn()

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

    // Shield glyph: filled when connected, outline when not.
    Canvas {
      id: canvas
      anchors.centerIn: parent
      width: 14
      height: 16
      readonly property color drawColor: root.connected ? Colors.primary : Colors.surfaceTextMuted
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
