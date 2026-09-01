import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Modules.Bar.Extras

// Wired-ethernet status via `nmcli device status`. Wifi.qml already covers wifi (Quickshell.Networking has no Ethernet type), so this fills the wired gap only; hidden entirely on machines with no ethernet interface.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  property bool ethernetPresent: false
  property bool ethernetConnected: false
  property string ethernetDevice: ""

  visible: ethernetPresent
  implicitWidth: visible ? 32 : 0
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  Process {
    id: statusProc
    command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]
    stdout: StdioCollector {
      onStreamFinished: {
        var present = false;
        var connected = false;
        var device = "";
        var lines = text.split("\n");
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split(":");
          if (parts.length < 3)
            continue;
          var dev = parts[0], type = parts[1], state = parts[2];
          if (type !== "ethernet")
            continue;
          present = true;
          if (state.indexOf("connected") === 0) {
            connected = true;
            device = dev;
          }
        }
        root.ethernetPresent = present;
        root.ethernetConnected = connected;
        root.ethernetDevice = device;
      }
    }
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!statusProc.running)
      statusProc.running = true
  }

  BarIconButton {
    id: btn
    attention: root.ethernetConnected

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
      readonly property color drawColor: root.ethernetConnected ? Color.primary : Color.outlineVariant
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
