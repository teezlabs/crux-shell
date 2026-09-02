import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs.Commons

// Notification history popup content: persistent log of past
// notifications, distinct from NotificationsWindow.qml's live toast
// stack. Hosted inside a SlideCard by PopupHost.qml — no
// window/positioning of its own.
ColumnLayout {
  id: root

  spacing: 10

  // Bound to the owning SlideCard's `open` from PopupHost.
  property bool active: false

  readonly property var history: Notifs.history

  // Forces relativeTime() text to re-evaluate periodically — Date.now() reads
  // inside a binding aren't tracked as a dependency on their own.
  property int _tick: 0
  Timer {
    interval: 30000
    running: root.active
    repeat: true
    onTriggered: root._tick++
  }

  function relativeTime(ts) {
    root._tick;
    var diff = Math.max(0, Date.now() - ts);
    var sec = Math.floor(diff / 1000);
    if (sec < 60)
      return "now";
    var min = Math.floor(sec / 60);
    if (min < 60)
      return min + "m";
    var hr = Math.floor(min / 60);
    if (hr < 24)
      return hr + "h";
    var day = Math.floor(hr / 24);
    return day + "d";
  }

  function urgencyColor(urgency) {
    return urgency === NotificationUrgency.Critical ? Color.primary : (urgency === NotificationUrgency.Low ? Color.outline : Color.tertiary);
  }

  RowLayout {
    Layout.fillWidth: true

    Text {
      text: "NOTIFICATIONS"
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelXsSize
      font.weight: Font.DemiBold
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
      Layout.fillWidth: true
    }

    Text {
      visible: root.history.length > 0
      text: "CLEAR ALL"
      color: Color.error
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelXsSize
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking

      HoverHandler {
        cursorShape: Qt.PointingHandCursor
      }
      TapHandler {
        onTapped: Notifs.clearHistory()
      }
    }
  }

  Text {
    visible: root.history.length === 0
    text: "No notifications yet"
    color: Color.labelText
    font.family: Tokens.fontFamily
    font.pixelSize: Tokens.bodySmSize
  }

  ListView {
    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(460, contentHeight)
    clip: true
    visible: root.history.length > 0
    model: root.history
    spacing: 2

    delegate: Item {
      id: rowItem
      required property var modelData
      width: ListView.view.width
      height: rowColumn.implicitHeight + 16

      Rectangle {
        anchors.fill: parent
        color: rowHover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer
      }

      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Tokens.borderMarker
        color: root.urgencyColor(rowItem.modelData.urgency)
      }

      HoverHandler {
        id: rowHover
      }

      ColumnLayout {
        id: rowColumn
        anchors.left: parent.left
        anchors.right: dismissText.left
        anchors.top: parent.top
        anchors.margins: 8
        anchors.leftMargin: 12
        anchors.rightMargin: 6
        spacing: 2

        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          Text {
            text: (rowItem.modelData.appName || "").toUpperCase()
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
            Layout.fillWidth: true
            elide: Text.ElideRight
          }

          Text {
            text: root.relativeTime(rowItem.modelData.timestamp)
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
          }
        }

        Text {
          Layout.fillWidth: true
          text: rowItem.modelData.summary || ""
          color: Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
          font.weight: Font.DemiBold
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          visible: (rowItem.modelData.body || "") !== ""
          text: rowItem.modelData.body || ""
          color: Color.surfaceTextMuted
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
          wrapMode: Text.WordWrap
          maximumLineCount: 2
          elide: Text.ElideRight
        }
      }

      Text {
        id: dismissText
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        text: "×"
        color: Color.labelText
        font.pixelSize: Tokens.bodyLgSize

        HoverHandler {
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: Notifs.removeFromHistory(rowItem.modelData.id)
        }
      }
    }
  }
}
