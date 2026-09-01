import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Modules.Bar.Extras

// Calendar popover: Monday-start month grid under the bar clock. No agenda list — no real event data source to bind to yet.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  property date viewDate: new Date()
  readonly property date today: new Date()

  function toggle() {
    visible = !visible;
    if (visible)
      viewDate = new Date();
  }

  function nextMonth() {
    var d = new Date(viewDate);
    d.setDate(1);
    d.setMonth(d.getMonth() + 1);
    viewDate = d;
  }

  function prevMonth() {
    var d = new Date(viewDate);
    d.setDate(1);
    d.setMonth(d.getMonth() - 1);
    viewDate = d;
  }

  // Monday-start 6-week grid covering the visible month, with a JS Date
  // per cell so out-of-month/today comparisons are exact.
  readonly property var gridDays: {
    var first = new Date(viewDate.getFullYear(), viewDate.getMonth(), 1);
    // getDay(): 0=Sun..6=Sat -> convert to Monday-start offset (0=Mon..6=Sun)
    var offset = (first.getDay() + 6) % 7;
    var start = new Date(first);
    start.setDate(first.getDate() - offset);

    var days = [];
    for (var i = 0; i < 42; i++) {
      var d = new Date(start);
      d.setDate(start.getDate() + i);
      days.push({
        "date": d,
        "day": d.getDate(),
        "inMonth": d.getMonth() === viewDate.getMonth(),
        "isToday": d.toDateString() === root.today.toDateString()
      });
    }
    return days;
  }

  visible: false
  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-calendar"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  IpcHandler {
    enabled: root.targetScreen === Quickshell.screens[0]
    target: "calendar"
    function toggle() {
      root.toggle();
    }
    function open() {
      root.visible = true;
      root.viewDate = new Date();
    }
    function close() {
      root.visible = false;
    }
  }

  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.visible = false
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.visible = false
  }

  Item {
    id: card
    width: 308
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: Settings.data.bar.thickness + Settings.data.bar.floatMargin * 2 + 8
    height: column.implicitHeight + 24

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutTopLeft: false
      cutTopRight: true
      cutBottomLeft: true
      cutBottomRight: false
      fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
      strokeColor: Color.outline
      strokeWidth: Tokens.borderPanel
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      id: column
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.margins: 14
      spacing: 10

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: Qt.formatDateTime(root.viewDate, "MMMM yyyy").toUpperCase()
          color: Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodyLgSize
          font.weight: Font.DemiBold
        }
        Item {
          Layout.fillWidth: true
        }
        Row {
          spacing: 12
          Text {
            text: "‹"
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodyLgSize
            HoverHandler {
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: root.prevMonth()
            }
          }
          Text {
            text: "›"
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodyLgSize
            HoverHandler {
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: root.nextMonth()
            }
          }
        }
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 7
        rowSpacing: 2
        columnSpacing: 2

        Repeater {
          model: ["M", "T", "W", "T", "F", "S", "S"]
          delegate: Text {
            required property string modelData
            Layout.preferredWidth: 36
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            text: modelData
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }
        }

        Repeater {
          model: root.gridDays
          delegate: Item {
            id: cell
            required property var modelData
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36

            Rectangle {
              anchors.fill: parent
              visible: cell.modelData.isToday
              color: Color.primaryContainer
            }
            Rectangle {
              visible: cell.modelData.isToday
              anchors.bottom: parent.bottom
              anchors.left: parent.left
              anchors.right: parent.right
              height: 2
              color: Color.primary
            }
            Text {
              anchors.centerIn: parent
              text: String(cell.modelData.day)
              color: cell.modelData.isToday ? Color.primaryContainerText : (cell.modelData.inMonth ? Color.surfaceText : Color.calendarOutOfMonth)
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySize
            }
          }
        }
      }
    }
  }
}
