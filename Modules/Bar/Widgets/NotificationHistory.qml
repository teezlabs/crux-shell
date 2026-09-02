import QtQuick
import Quickshell
import qs.Modules.Bar.Extras
import qs.Commons

// Bell icon on the bar; the persistent history list lives in the
// notificationHistory popup hosted by PopupHost.qml (distinct from the
// live toast stack in NotificationsWindow.qml). Small dot badge when
// history has entries — real count, not decorative.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  readonly property int historyCount: Notifs.history.length

  implicitWidth: btn.implicitWidth
  implicitHeight: btn.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarIconButton {
    id: btn
    onTapped: {
      var pos = root.mapToItem(null, 0, 0);
      Quickshell.execDetached(["qs", "ipc", "-c", "crux", "call", "notificationHistory_" + (root.screen ? root.screen.name : "0"), "openAt", String(pos.x), String(pos.y)]);
    }

    // Geometric bell glyph — body + clapper, no font/emoji dependency.
    Canvas {
      anchors.centerIn: parent
      width: 12
      height: 13
      readonly property color strokeColor: Color.surfaceText
      onStrokeColorChanged: requestPaint()
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = strokeColor;
        ctx.lineWidth = 1.2;
        ctx.lineJoin = "round";
        ctx.beginPath();
        // Bell body
        ctx.moveTo(1, 9);
        ctx.lineTo(1, 6);
        ctx.bezierCurveTo(1, 2.5, 3.5, 1, 6, 1);
        ctx.bezierCurveTo(8.5, 1, 11, 2.5, 11, 6);
        ctx.lineTo(11, 9);
        ctx.stroke();
        // Bottom rail
        ctx.beginPath();
        ctx.moveTo(0.5, 9);
        ctx.lineTo(11.5, 9);
        ctx.stroke();
        // Clapper
        ctx.beginPath();
        ctx.arc(6, 11.5, 1.3, 0, Math.PI * 2);
        ctx.stroke();
      }
    }

    Rectangle {
      visible: root.historyCount > 0
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: 4
      anchors.rightMargin: 4
      width: 5
      height: 5
      radius: 0
      color: Color.tertiary
    }
  }
}
