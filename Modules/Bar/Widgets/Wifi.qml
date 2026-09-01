import QtQuick
import Quickshell.Networking
import qs.Modules.Bar.Extras
import qs.Commons

// Wi-Fi status icon on the bar; the real network list/connect UI lives in
// the separate WifiMenuWindow popup (StatusGroup's NET segment is a
// summary-only readout, this owns the actual device list).
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  readonly property var wifiDevice: {
    var devices = Networking.devices ? Networking.devices.values : [];
    for (var i = 0; i < devices.length; i++) {
      if (devices[i] && devices[i].type === DeviceType.Wifi)
        return devices[i];
    }
    return null;
  }
  readonly property var connectedNetwork: {
    var networks = wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : [];
    for (var i = 0; i < networks.length; i++) {
      if (networks[i] && networks[i].connected)
        return networks[i];
    }
    return null;
  }

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  WifiMenuWindow {
    id: menu
    targetScreen: root.screen
  }

  BarIconButton {
    id: btn
    onTapped: {
      menu.triggerPos = root.mapToItem(null, 0, 0);
      menu.toggle();
    }

    // Standard wifi-fan glyph (three concentric arcs + a dot) drawn on
    // Canvas — no font/emoji glyph dependency.
    Canvas {
      id: wifiCanvas
      anchors.centerIn: parent
      width: 16
      height: 12
      readonly property color drawColor: !Networking.wifiEnabled ? Color.disabledText : (root.connectedNetwork ? Color.primary : Color.surfaceTextMuted)
      onDrawColorChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = drawColor;
        ctx.fillStyle = drawColor;
        ctx.lineWidth = 1.6;
        ctx.lineCap = "round";
        var cx = width / 2;
        var cy = height - 1;

        for (var i = 0; i < 3; i++) {
          var radius = 3 + i * 4;
          ctx.beginPath();
          ctx.arc(cx, cy, radius, Math.PI * 1.25, Math.PI * 1.75);
          ctx.stroke();
        }

        ctx.beginPath();
        ctx.arc(cx, cy, 1.3, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }
}
