import QtQuick
import Quickshell
import qs.Commons

// Plain picture-frame icon on the bar. skwd-wall is its own standalone qs
// config (ephemeral: spawns fresh, auto-shows, exits itself when closed),
// not a panel embedded here — same command the SUPER+W keybind runs. See
// crux skill's wallpaper section for why: skwd-wall's real UI only behaves
// correctly with a genuine interactive session (mouse/keyboard presence),
// not when driven headlessly, which ruled out embedding it as a Loader-
// managed popup the way other bar widgets' menus work.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  implicitWidth: 32
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  Rectangle {
    anchors.fill: parent
    anchors.margins: 4
    radius: Style.radiusXXS
    color: hoverHandler.hovered ? Color.mOutline : "transparent"

    // Geometric picture-frame glyph: a rounded rect outline with a small
    // mountain/sun icon inside — no font/emoji glyph dependency.
    Canvas {
      anchors.centerIn: parent
      width: 16
      height: 14
      readonly property color drawColor: Color.mOnSurfaceVariant
      onDrawColorChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = drawColor;
        ctx.fillStyle = drawColor;
        ctx.lineWidth = 1.4;

        ctx.beginPath();
        ctx.roundedRect(0.7, 0.7, width - 1.4, height - 1.4, 2, 2);
        ctx.stroke();

        ctx.beginPath();
        ctx.arc(4.5, 4.5, 1.3, 0, Math.PI * 2);
        ctx.fill();

        ctx.beginPath();
        ctx.moveTo(1.5, height - 2);
        ctx.lineTo(6, 6.5);
        ctx.lineTo(9, 10);
        ctx.lineTo(11, 7.5);
        ctx.lineTo(width - 1.5, height - 2);
        ctx.closePath();
        ctx.fill();
      }
    }
  }

  HoverHandler {
    id: hoverHandler
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: Quickshell.execDetached(["qs", "-c", "skwd-wall"])
  }
}
