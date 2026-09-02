import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.Modules.Bar.Extras
import qs.Commons

// Bluetooth status icon on the bar; the real device list/connect UI lives
// in the bluetooth popup hosted by PopupHost.qml.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  readonly property var adapter: Bluetooth.defaultAdapter
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

  BarIconButton {
    id: btn
    onTapped: {
      var pos = root.mapToItem(null, 0, 0);
      Quickshell.execDetached(["qs", "ipc", "-c", "crux", "call", "bluetooth_" + (root.screen ? root.screen.name : "0"), "openAt", String(pos.x), String(pos.y)]);
    }

    // Geometric "B"-glyph stand-in (bowtie) — no font/emoji glyph dependency.
    Canvas {
      anchors.centerIn: parent
      width: 10
      height: 14
      readonly property color strokeColor: !root.adapter || !root.adapter.enabled ? Color.disabledText : (root.anyConnected ? Color.primary : Color.surfaceTextMuted)
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
