import QtQuick
import qs.Commons

// Vertical-stacked clock: hour on top, minute on bottom. No card/background
// — just the digits, letting the bold hour + accent-colored minute carry
// it instead of a boxed-in shape.
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

  implicitWidth: 32
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

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

    // Colon-style divider, two small dots instead of a flat rule.
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
