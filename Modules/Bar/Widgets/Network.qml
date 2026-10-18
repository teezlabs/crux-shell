import QtQuick
import qs.Commons
import qs.Services
import qs.Modules.Bar.Extras

// Wired-ethernet status from NetworkManager. Wifi.qml already covers wifi (Quickshell.Networking has no Ethernet type), so this fills the wired gap only; hidden entirely on machines with no ethernet interface.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool invertChamfer: false

  readonly property bool ethernetPresent: NetworkManager.ethernetPresent
  readonly property bool ethernetConnected: NetworkManager.ethernetConnected
  readonly property string ethernetDevice: NetworkManager.ethernetDevice

  visible: ethernetPresent
  implicitWidth: visible ? 32 : 0
  implicitHeight: Tokens.barCell
  width: implicitWidth
  height: implicitHeight

  BarIconButton {
    id: btn
    invertChamfer: root.invertChamfer

    HoverHandler {
      cursorShape: Qt.PointingHandCursor
      onHoveredChanged: {
        if (hovered) {
          TooltipService.show(root, root.ethernetConnected ? "Ethernet: " + root.ethernetDevice + " (connected)" : "Ethernet: cable unplugged");
        } else {
          TooltipService.hide();
        }
      }
    }

    // Ethernet plug glyph: a small jack body + two prongs, no font/emoji
    // glyph dependency. Solid when connected, outline/dim when the
    // interface exists but the cable is unplugged.
    Canvas {
      id: canvas
      anchors.centerIn: parent
      width: 16
      height: 14
      readonly property color drawColor: root.ethernetConnected ? Colors.primary : Colors.outlineVariant
      onDrawColorChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = drawColor;
        ctx.fillStyle = drawColor;
        ctx.lineWidth = 1.4;
        ctx.lineCap = "round";

        // Jack body
        ctx.beginPath();
        ctx.rect(3, 5, 10, 8);
        ctx.stroke();

        // Two prongs on top
        ctx.beginPath();
        ctx.moveTo(6, 5);
        ctx.lineTo(6, 1);
        ctx.moveTo(10, 5);
        ctx.lineTo(10, 1);
        ctx.stroke();

        // Contact line inside the jack
        ctx.beginPath();
        ctx.moveTo(5, 9);
        ctx.lineTo(11, 9);
        ctx.stroke();
      }
    }
  }
}
