import QtQuick
import Quickshell
import Quickshell.Networking
import qs.Modules.Popups
import qs.Commons
import qs.Widgets
import qs.Modules.Bar.Extras

// Wi-Fi status icon on the bar; the real network list/connect UI lives in
// the wifi popup hosted by PopupHost.qml (StatusGroup's NET segment is a
// summary-only readout, this owns the actual device list).
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property bool invertChamfer: false

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

  BarPill {
    id: btn
    invertChamfer: root.invertChamfer
    vertical: root.vertical
    label: root.connectedNetwork ? (root.connectedNetwork.ssid || "") : (Networking.wifiEnabled ? "Not connected" : "Off")
    onTapped: {
      var pos = root.mapToItem(null, 0, 0);
      Popups.openFrom("wifi", root.screen, pos.x, pos.y, root.width, root.height);
    }

    WifiGlyph {
      anchors.centerIn: parent
      color: !Networking.wifiEnabled ? Colors.disabledText : (root.connectedNetwork ? Colors.primary : Colors.surfaceTextMuted)
    }
  }
}
