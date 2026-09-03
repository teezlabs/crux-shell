import QtQuick
import Quickshell.Services.UPower
import qs.Commons
import qs.Modules.Bar.Extras

// Current power profile; click cycles power-saver -> balanced ->
// performance. Hidden entirely on a machine with no power-profiles-daemon.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool invertChamfer: false
  property bool vertical: false

  // A binding, not a snapshot — see Commons/PowerProfileService.qml.
  visible: PowerProfileService.available

  implicitWidth: visible ? btn.implicitWidth : 0
  implicitHeight: visible ? btn.implicitHeight : 0
  width: implicitWidth
  height: implicitHeight

  BarPill {
    id: btn
    invertChamfer: root.invertChamfer
    attention: PowerProfileService.degraded
    vertical: root.vertical
    // Name the profile while hovered, and stay out while it's a state the
    // user chose rather than the default.
    label: PowerProfileService.name()
    forceOpen: PowerProfileService.profile !== PowerProfile.Balanced
    onTapped: PowerProfileService.cycle()

    // Leaf / gauge / bolt for power-saver / balanced / performance, drawn
    // geometrically — no glyph font dependency.
    Canvas {
      anchors.centerIn: parent
      width: 16
      height: 16

      readonly property int profile: PowerProfileService.profile
      readonly property color drawColor: {
        if (PowerProfileService.degraded)
          return Color.tertiary;
        return profile === PowerProfile.Balanced ? Color.surfaceTextMuted : Color.primary;
      }
      onProfileChanged: requestPaint()
      onDrawColorChanged: requestPaint()

      onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = drawColor;
        ctx.fillStyle = drawColor;
        ctx.lineWidth = 1.4;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        const cx = width / 2;
        const cy = height / 2;

        if (profile === PowerProfile.Performance) {
          // Lightning bolt.
          ctx.beginPath();
          ctx.moveTo(cx + 2.5, 1);
          ctx.lineTo(cx - 3.5, cy + 0.5);
          ctx.lineTo(cx - 0.5, cy + 0.5);
          ctx.lineTo(cx - 2.5, height - 1);
          ctx.lineTo(cx + 3.5, cy - 0.5);
          ctx.lineTo(cx + 0.5, cy - 0.5);
          ctx.closePath();
          ctx.fill();
        } else if (profile === PowerProfile.PowerSaver) {
          // Leaf: two opposed arcs plus a midrib.
          ctx.beginPath();
          ctx.moveTo(cx - 5, cy + 5);
          ctx.quadraticCurveTo(cx - 5, cy - 5, cx + 5, cy - 5);
          ctx.quadraticCurveTo(cx + 5, cy + 5, cx - 5, cy + 5);
          ctx.closePath();
          ctx.stroke();
          ctx.beginPath();
          ctx.moveTo(cx - 3, cy + 3);
          ctx.lineTo(cx + 3, cy - 3);
          ctx.stroke();
        } else {
          // Balanced: a gauge arc with a needle.
          ctx.beginPath();
          ctx.arc(cx, cy + 3, 5.5, Math.PI, Math.PI * 2);
          ctx.stroke();
          ctx.beginPath();
          ctx.moveTo(cx, cy + 3);
          ctx.lineTo(cx + 3, cy - 2);
          ctx.stroke();
        }
      }
    }

  }

  HoverHandler {
    onHoveredChanged: {
      if (hovered)
        TooltipService.show(root, PowerProfileService.name() + (PowerProfileService.degraded ? " (degraded)" : ""));
      else
        TooltipService.hide();
    }
  }
}
