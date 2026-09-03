import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras

// Hue bulb status icon on the bar; brightness/color control lives in the
// hue popup hosted by PopupHost.qml, pairing setup lives in Settings → Hue.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  readonly property var group: Hue.selectedGroup
  readonly property bool lit: Hue.paired && group && group.on

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarIconButton {
    id: btn
    attention: root.lit
    onTapped: {
      var pos = root.mapToItem(null, 0, 0);
      Popups.openAt("hue", root.screen, pos.x, pos.y);
    }
    onSecondaryTapped: {
      if (Hue.paired && root.group)
        root.group.setOn(!root.group.on);
    }

    // Geometric bulb glyph: round head + screw-base lines — no font/emoji
    // glyph dependency.
    Canvas {
      anchors.centerIn: parent
      width: 12
      height: 14
      readonly property color drawColor: !Hue.paired ? Color.disabledText : (root.lit ? Color.primary : Color.surfaceTextMuted)
      onDrawColorChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = drawColor;
        ctx.fillStyle = drawColor;
        ctx.lineWidth = 1.2;

        // Bulb head
        ctx.beginPath();
        ctx.arc(width / 2, 5, 4.5, 0, Math.PI * 2);
        if (root.lit)
          ctx.fill();
        else
          ctx.stroke();

        // Screw base (two rungs + bottom cap)
        ctx.beginPath();
        ctx.moveTo(width / 2 - 2, 9);
        ctx.lineTo(width / 2 + 2, 9);
        ctx.moveTo(width / 2 - 2, 11);
        ctx.lineTo(width / 2 + 2, 11);
        ctx.stroke();
        ctx.fillRect(width / 2 - 1.5, 12, 3, 1.5);
      }
    }
  }
}
