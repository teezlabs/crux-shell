import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras

// Toggles the Sidebar dashboard (§6.8).
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool invertChamfer: false

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarIconButton {
    id: btn
    invertChamfer: root.invertChamfer
    onTapped: Popups.toggle("sidebar", root.screen);

    // Three stacked bars, left one accented — a "sidebar" glyph.
    Canvas {
      anchors.centerIn: parent
      width: 14
      height: 12
      readonly property color accentColor: Colors.primary
      readonly property color trackColor: Colors.surfaceTextMuted
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
