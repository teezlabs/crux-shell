import QtQuick
import qs.Commons

// Minimal bar clock. Styling is intentionally plain for now — theming comes later.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  property date now: new Date()

  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
  }

  // implicitHeight fixed at 32 to match every other bar widget — see the
  // same fix/comment in Workspaces.qml for why a shorter implicitHeight
  // here would misalign this widget within BarSection's Row.
  implicitWidth: label.implicitWidth + 16
  implicitHeight: 32
  width: implicitWidth
  height: implicitHeight

  Text {
    id: label
    anchors.centerIn: parent
    text: Qt.formatDateTime(root.now, "ddd MMM d  hh:mm:ss")
    color: Color.mOnSurface
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: 13
  }
}
