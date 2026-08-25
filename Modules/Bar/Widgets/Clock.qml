import QtQuick
import qs.Commons

// Vertical-stacked clock: hour on top, minute on bottom, in a small tinted
// card — used the same way regardless of bar orientation, since a single
// "Wed Mar 4  14:32:07" line never fit a narrow vertical bar anyway (see
// crux skill's positioner-anchor gotcha) and reads better stacked than
// horizontal even on a top/bottom bar. 24-hour format, since a 2-row
// stack has no room left for an AM/PM marker without a 3rd row.
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

  implicitWidth: 34
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  Rectangle {
    id: card
    anchors.fill: parent
    radius: Style.radiusXS
    color: Color.alpha(Color.mPrimary, 0.08)
    border.color: Color.alpha(Color.mPrimary, 0.4)
    border.width: 1

    // Column is a positioner — a child setting its own anchors conflicts
    // with it and silently produces broken geometry (documented in the
    // crux skill after this exact bug once made the whole clock vanish).
    // Every child below gets an explicit width/x instead of anchors.
    Column {
      anchors.centerIn: parent
      spacing: 2

      Text {
        width: 26
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDateTime(root.now, "HH")
        color: Color.mOnSurface
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: 13
        font.bold: true
      }

      Rectangle {
        x: (26 - 16) / 2
        width: 16
        height: 1
        color: Color.alpha(Color.mPrimary, 0.6)
      }

      Text {
        width: 26
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDateTime(root.now, "mm")
        color: Color.mPrimary
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: 12
      }
    }
  }
}
