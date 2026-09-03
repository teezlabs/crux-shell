import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras

// Bar icon toggling the Sidebar Dashboard (§6.8) — previously only
// reachable via `qs ipc call sidebar toggle`, no bar entry point existed.
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
    onTapped: Popups.toggle("sidebar", root.screen);

    // Three stacked bars, left one accented — a "sidebar" glyph.
    Canvas {
      anchors.centerIn: parent
      width: 14
      height: 12
      readonly property color accentColor: Color.primary
      readonly property color trackColor: Color.surfaceTextMuted
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = accentColor;
        ctx.fillRect(0, 0, 4, height);
        ctx.strokeStyle = trackColor;
        ctx.lineWidth = 1.2;
        ctx.strokeRect(0.5, 0.5, width - 1, height - 1);
      }
    }
  }
}
