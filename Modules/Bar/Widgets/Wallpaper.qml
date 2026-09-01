import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras

// Picture-frame icon on the bar — opens this screen's own
// WallpaperBrowserWindow instance (same command SUPER+W runs via
// bin/crux-focused-ipc). See crux skill's notes.md.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarIconButton {
    id: btn
    onTapped: {
      TooltipService.hideImmediately();
      Quickshell.execDetached(["qs", "ipc", "-c", "crux", "call", "wallpaperBrowser_" + (root.screen ? root.screen.name : "0"), "toggle"]);
    }

    HoverHandler {
      cursorShape: Qt.PointingHandCursor
      onHoveredChanged: {
        if (hovered)
          TooltipService.show(root, "Open wallpaper picker (SUPER+W)");
        else
          TooltipService.hide();
      }
    }

    // Geometric picture-frame glyph: an outline with a small mountain/sun
    // icon inside — no font/emoji glyph dependency.
    Canvas {
      anchors.centerIn: parent
      width: 16
      height: 14
      readonly property color drawColor: Color.surfaceTextMuted
      onDrawColorChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = drawColor;
        ctx.fillStyle = drawColor;
        ctx.lineWidth = 1.4;

        ctx.strokeRect(0.7, 0.7, width - 1.4, height - 1.4);

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
}
