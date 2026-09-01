import QtQuick
import qs.Commons
import qs.Modules.Bar.Extras

// Date · divider · time on a horizontal bar; stacked date/time on a vertical bar (doesn't fit one line at ~32px wide).
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

  implicitWidth: module.implicitWidth
  implicitHeight: module.implicitHeight
  width: implicitWidth
  height: implicitHeight

  CalendarWindow {
    id: calendar
    targetScreen: root.screen
  }

  HoverHandler {
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    onTapped: calendar.toggle()
  }

  BarModule {
    id: module
    vertical: root.vertical

    Row {
      visible: !root.vertical
      spacing: 8

      Text {
        text: Qt.formatDateTime(root.now, Settings.data.ui.dateFormat).toUpperCase()
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.captionSize
        font.letterSpacing: Tokens.captionSize * Tokens.captionTracking
      }

      Rectangle {
        width: 1
        height: 12
        color: Color.surfaceContainerHigh
      }

      Text {
        text: Qt.formatDateTime(root.now, Settings.data.ui.clockFormat)
        color: Color.surfaceText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySize
        font.weight: Font.DemiBold
        font.letterSpacing: Tokens.bodySize * Tokens.bodyTracking
      }
    }

    Column {
      visible: root.vertical
      spacing: 1

      Text {
        width: 30
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDateTime(root.now, "HH")
        color: Color.surfaceText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySize
        font.weight: Font.DemiBold
      }
      Text {
        width: 30
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDateTime(root.now, "mm")
        color: Color.surfaceText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySize
        font.weight: Font.DemiBold
      }
      Text {
        width: 30
        horizontalAlignment: Text.AlignHCenter
        text: Qt.formatDateTime(root.now, "dd/MM")
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.labelXsSize
      }
    }
  }
}
