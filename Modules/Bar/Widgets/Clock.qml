import QtQuick
import QtQuick.Effects
import qs.Commons

// Vertical-stacked clock: hour on top, minute on bottom, inside a slanted
// parallelogram card — the same skwd-derived geometric accent as the active
// workspace pill (Workspaces.qml), applied here instead of a plain flat
// rounded box since a persistent, always-visible widget like the clock is
// exactly the kind of "shit looking" flat box the user called out. Text
// itself stays unskewed (a sibling overlay, not drawn inside the skewed
// Canvas shape) so the digits stay perfectly legible — same technique as
// the workspace pill.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false

  property date now: new Date()

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
  }

  implicitWidth: 36
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  Canvas {
    id: cardShape
    anchors.fill: parent
    anchors.margins: 1
    readonly property color c1: Color.mSurfaceVariant
    readonly property color c2: Color.alpha(Color.mPrimary, 0.28)
    readonly property color strokeC: Color.alpha(Color.mPrimary, 0.65)
    onC1Changed: requestPaint()
    onC2Changed: requestPaint()
    onPaint: {
      var ctx = getContext("2d");
      ctx.reset();
      var skew = height * 0.16;
      var grad = ctx.createLinearGradient(0, 0, 0, height);
      grad.addColorStop(0, c1);
      grad.addColorStop(1, c2);
      ctx.fillStyle = grad;
      ctx.strokeStyle = strokeC;
      ctx.lineWidth = 1;
      ctx.beginPath();
      ctx.moveTo(skew, 0);
      ctx.lineTo(width, 0);
      ctx.lineTo(width - skew, height);
      ctx.lineTo(0, height);
      ctx.closePath();
      ctx.fill();
      ctx.stroke();
    }
  }

  // Soft ambient glow behind the card — subtler than the workspace pill's
  // (this is always on, not an active-state toggle), just enough to keep
  // the clock from reading as a flat box against the bar background.
  MultiEffect {
    anchors.fill: cardShape
    source: cardShape
    shadowEnabled: true
    shadowColor: Color.mPrimary
    shadowBlur: 0.35
    shadowOpacity: 0.35
  }

  Column {
    anchors.centerIn: parent
    spacing: 2

    Text {
      width: 30
      horizontalAlignment: Text.AlignHCenter
      text: Qt.formatDateTime(root.now, "HH")
      color: Color.mOnSurface
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: 15
      font.bold: true
      font.letterSpacing: 1
    }

    // Colon-style divider, two small glowing dots instead of a flat rule.
    Row {
      x: (30 - width) / 2
      spacing: 3

      Rectangle {
        width: 3
        height: 3
        radius: 1.5
        color: Color.mPrimary
      }
      Rectangle {
        width: 3
        height: 3
        radius: 1.5
        color: Color.mPrimary
      }
    }

    Text {
      width: 30
      horizontalAlignment: Text.AlignHCenter
      text: Qt.formatDateTime(root.now, "mm")
      color: Color.mPrimary
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: 13
      font.bold: true
      font.letterSpacing: 1
    }
  }
}
