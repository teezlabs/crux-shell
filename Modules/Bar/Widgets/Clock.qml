import QtQuick
import qs.Commons

// Minimal bar clock. Styling is intentionally plain for now — theming comes later.
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

  // implicitHeight fixed at 32 (horizontal) to match every other bar widget
  // — see the same fix/comment in Workspaces.qml for why a shorter
  // implicitHeight would misalign this widget within BarSection's Grid.
  // Vertical mode swaps to a narrow fixed width and a height that grows to
  // fit the stacked date/time lines instead — a single wide line like the
  // horizontal one doesn't fit a narrow vertical bar at all.
  implicitWidth: root.vertical ? 32 : (label.implicitWidth + 16)
  implicitHeight: root.vertical ? (column.implicitHeight + 10) : 32
  width: implicitWidth
  height: implicitHeight

  Text {
    id: label
    visible: !root.vertical
    anchors.centerIn: parent
    text: Qt.formatDateTime(root.now, "ddd MMM d  hh:mm:ss")
    color: Color.mOnSurface
    font.family: Settings.data.ui.fontFamily
    font.pixelSize: 13
  }

  // Stacked date/time for a vertical bar — seconds dropped, one line of
  // horizontal text like the label above simply doesn't fit a ~32px-wide
  // column no matter how it's formatted.
  Column {
    id: column
    visible: root.vertical
    anchors.centerIn: parent
    spacing: 1

    // Column is a positioner — it sets its children's x/y itself, so a
    // child anchoring its own horizontalCenter conflicts with that and
    // silently produces broken/zero geometry (this is what was actually
    // making the whole clock disappear, not a sizing miscalculation).
    // Giving both Text items the same explicit width and letting
    // horizontalAlignment center the glyphs within it achieves the same
    // visual result without touching anchors.
    Text {
      width: 28
      horizontalAlignment: Text.AlignHCenter
      text: Qt.formatDateTime(root.now, "MMM\nd")
      color: Color.mOnSurfaceVariant
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: 9
      lineHeight: 0.9
    }
    Text {
      width: 28
      horizontalAlignment: Text.AlignHCenter
      text: Qt.formatDateTime(root.now, "hh:mm")
      color: Color.mOnSurface
      font.family: Settings.data.ui.fontFamily
      font.pixelSize: 11
    }
  }
}
