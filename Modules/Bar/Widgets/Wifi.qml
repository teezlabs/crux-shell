import QtQuick
import Quickshell.Networking
import qs.Modules.Bar.Extras

// Plain Wi-Fi status icon on the bar; the real network list/connect UI lives
// in the separate WifiMenuWindow popup.
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

  implicitWidth: 32
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  WifiMenuWindow {
    id: menu
    targetScreen: root.screen
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: 4
    radius: 2
    color: mouseArea.containsMouse ? "#45475a" : "transparent"

    Text {
      anchors.centerIn: parent
      text: "📶"
      font.pixelSize: 15
      opacity: !Networking.wifiEnabled ? 0.35 : (root.connectedNetwork ? 1.0 : 0.6)
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: menu.toggle()
  }
}
