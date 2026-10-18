import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.Modules.Popups
import qs.Commons
import qs.Modules.Bar.Extras

// Bluetooth status icon; the device list lives in the bluetooth popup.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property bool invertChamfer: false

  readonly property var adapter: Bluetooth.defaultAdapter
  // Name of the first connected device, for the pill label.
  readonly property string connectedName: {
    const devices = Bluetooth.devices ? Bluetooth.devices.values : [];
    for (let i = 0; i < devices.length; i++) {
      if (devices[i] && devices[i].connected)
        return devices[i].name || devices[i].deviceName || "";
    }
    return "";
  }

  readonly property bool anyConnected: {
    var devices = Bluetooth.devices ? Bluetooth.devices.values : [];
    for (var i = 0; i < devices.length; i++) {
      if (devices[i] && devices[i].connected)
        return true;
    }
    return false;
  }

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarPill {
    id: btn
    invertChamfer: root.invertChamfer
    vertical: root.vertical
    label: root.connectedName !== "" ? root.connectedName : (root.adapter && root.adapter.enabled ? "No device" : "Off")
    onTapped: {
      var pos = root.mapToItem(null, 0, 0);
      Popups.openFrom("bluetooth", root.screen, pos.x, pos.y, root.width, root.height);
    }

    // Geometric "B"-glyph stand-in (bowtie) — no font/emoji glyph dependency.
    Canvas {
      anchors.centerIn: parent
      width: 10
      height: 14
      readonly property color strokeColor: !root.adapter || !root.adapter.enabled ? Colors.disabledText : (root.anyConnected ? Colors.primary : Colors.surfaceTextMuted)
      onStrokeColorChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = strokeColor;
        ctx.lineWidth = 1.4;
        ctx.beginPath();
        ctx.moveTo(width / 2, 0);
        ctx.lineTo(width / 2, height);
        ctx.moveTo(0, height * 0.25);
        ctx.lineTo(width, height * 0.75);
        ctx.lineTo(width / 2, height);
        ctx.moveTo(0, height * 0.75);
        ctx.lineTo(width, height * 0.25);
        ctx.lineTo(width / 2, 0);
        ctx.stroke();
      }
    }
  }
}
