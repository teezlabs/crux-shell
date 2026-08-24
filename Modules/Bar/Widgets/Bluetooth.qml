import QtQuick
import Quickshell.Bluetooth
import qs.Modules.Bar.Extras
import qs.Commons

// Plain Bluetooth status icon on the bar; the real device list/connect UI
// lives in the separate BluetoothMenuWindow popup.
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

  implicitWidth: 32
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  BluetoothMenuWindow {
    id: menu
    targetScreen: root.screen
  }

  Rectangle {
    anchors.fill: parent
    anchors.margins: 4
    radius: Style.radiusXXS
    color: hoverHandler.hovered ? Color.mOutline : "transparent"

    // Geometric "B"-glyph stand-in (bowtie) — no font/emoji glyph dependency.
    Canvas {
      anchors.centerIn: parent
      width: 10
      height: 14
      readonly property color strokeColor: !root.adapter || !root.adapter.enabled ? Color.mOutline : (root.anyConnected ? Color.mPrimary : Color.mOnSurfaceVariant)
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

  HoverHandler {
    id: hoverHandler
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: menu.toggle()
  }
}
