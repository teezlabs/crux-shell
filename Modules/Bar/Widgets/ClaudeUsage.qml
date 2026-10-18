import QtQuick
import qs.Commons
import qs.Services
import qs.Modules.Popups
import qs.Modules.Bar.Extras

// Compact session-usage readout; full detail lives in the claudeUsage popup.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool invertChamfer: false

  readonly property var sessionLimit: ClaudeUsageService.sessionLimit
  readonly property real sessionPercent: sessionLimit ? sessionLimit.percent : -1
  readonly property var weeklyLimit: ClaudeUsageService.weeklyLimit
  readonly property real weeklyPercent: weeklyLimit ? weeklyLimit.percent : -1

  Component.onCompleted: ClaudeUsageService.watchers++
  Component.onDestruction: ClaudeUsageService.watchers--

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarIconButton {
    id: btn
    invertChamfer: root.invertChamfer
    attention: root.sessionPercent > 0.85
    onTapped: {
      var pos = root.mapToItem(null, 0, 0);
      Popups.openFrom("claudeUsage", root.screen, pos.x, pos.y, root.width, root.height);
    }

    // Robot glyph drawn on a Canvas: head outline, two eyes, antenna.
    Canvas {
      anchors.centerIn: parent
      width: 14
      height: 14
      readonly property color drawColor: root.sessionPercent > 0.85 ? Colors.tertiary : Colors.surfaceText
      onDrawColorChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = drawColor;
        ctx.fillStyle = drawColor;
        ctx.lineWidth = 1.3;

        ctx.beginPath();
        ctx.moveTo(7, 0.5);
        ctx.lineTo(7, 2.5);
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(7, 0.5, 0.9, 0, Math.PI * 2);
        ctx.fill();

        ctx.strokeRect(1, 2.5, 12, 10);

        ctx.beginPath();
        ctx.arc(4.5, 7, 1, 0, Math.PI * 2);
        ctx.fill();
        ctx.beginPath();
        ctx.arc(9.5, 7, 1, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }
}
