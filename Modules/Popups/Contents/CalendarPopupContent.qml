import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Calendar popup content: Monday-start month grid. No agenda list — no real
// event data source to bind to yet.
ColumnLayout {
  id: root

  spacing: Tokens.spaceLg

  property date viewDate: new Date()
  readonly property date today: new Date()

  // PopupHost calls this when the card opens, so reopening always lands on
  // the current month rather than wherever the user last paged to.
  function reset(): void {
    root.viewDate = new Date();
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

  RowLayout {
    Layout.fillWidth: true

    NText {
      text: Qt.formatDateTime(root.viewDate, "MMMM yyyy").toUpperCase()
      color: Colors.surfaceText
      size: NText.Size.BodyLg
      font.weight: Font.DemiBold
    }
    Item {
      Layout.fillWidth: true
    }
    Row {
      spacing: 12
      NText {
        text: "‹"
        color: Colors.labelText
        size: NText.Size.BodyLg
        HoverHandler {
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: root.prevMonth()
        }
      }
      NText {
        text: "›"
        color: Colors.labelText
        size: NText.Size.BodyLg
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
      delegate: NText {
        required property string modelData
        Layout.preferredWidth: 36
        Layout.alignment: Qt.AlignHCenter
        horizontalAlignment: Text.AlignHCenter
        text: modelData
        color: Colors.labelText
        size: NText.Size.LabelXs
        tracking: true
      }
    }

    Repeater {
      model: root.gridDays
      delegate: Item {
        id: cell
        required property var modelData
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36

        Chamfer {
          anchors.fill: parent
          visible: cell.modelData.isToday
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: Colors.primary
        }
        NText {
          anchors.centerIn: parent
          text: String(cell.modelData.day)
          color: cell.modelData.isToday ? Colors.primaryText : (cell.modelData.inMonth ? Colors.surfaceText : Colors.calendarOutOfMonth)
        }
      }
    }
  }
}
