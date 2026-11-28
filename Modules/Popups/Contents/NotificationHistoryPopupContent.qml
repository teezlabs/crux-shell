import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs.Commons
import qs.Widgets
import qs.Modules.Notifications
import qs.Modules.Popups
import qs.Services

// Notification history, one entry per conversation (Notifs.conversations); tap one to read its whole thread.
ColumnLayout {
  id: root

  spacing: Tokens.spaceLg

  // Bound to the owning SlideCard's `open` from PopupHost.
  property bool active: false

  readonly property var history: Notifs.history
  // Conversation key -> true while expanded.
  property var expanded: ({})

  function toggle(key) {
    const next = Object.assign({}, root.expanded);
    next[key] = !next[key];
    root.expanded = next;
  }

  function plain(text) {
    return (text || "").replace(/<[^>]*>/g, "").replace(/\n/g, " ");
  }

  // Date.now() isn't a binding dependency, so the tick re-evaluates relative times.
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
    return urgency === NotificationUrgency.Critical ? Colors.primary : (urgency === NotificationUrgency.Low ? Colors.outline : Colors.tertiary);
  }

  PopupHeader {
    title: "NOTIFICATIONS"
    action: root.history.length > 0 ? "CLEAR ALL" : ""
    onActionTapped: Notifs.clearHistory()
  }

  NText {
    visible: root.history.length === 0
    text: "No notifications yet"
    color: Colors.labelText
    size: NText.Size.BodySm
  }

  ListView {
    id: scrollView
    layer.enabled: scrollFade.active
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: scrollFade
      maskThresholdMin: 0.5
      maskSpreadAtMin: 1
    }
    NSmoothWheel {
      flickable: scrollView
    }
    NScrollFade {
      id: scrollFade
      flickable: scrollView
    }
    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(460, contentHeight)
    clip: true
    visible: root.history.length > 0
    model: Notifs.conversations
    spacing: 2

    delegate: Item {
      id: rowItem
      required property var modelData
      readonly property var latest: modelData.messages[0]
      readonly property int count: modelData.messages.length
      readonly property bool open: !!root.expanded[modelData.key]
      width: ListView.view.width
      height: rowColumn.implicitHeight + 16

      Rectangle {
        anchors.fill: parent
        color: rowHover.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer
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
        cursorShape: rowItem.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
      }
      TapHandler {
        enabled: rowItem.count > 1
        onTapped: root.toggle(rowItem.modelData.key)
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

          NText {
            tracking: true
            text: (rowItem.modelData.appName || "").toUpperCase()
            color: Colors.labelText
            size: NText.Size.LabelXs
            Layout.fillWidth: true
            elide: Text.ElideRight
          }

          NText {
            text: root.relativeTime(rowItem.modelData.timestamp)
            color: Colors.labelText
            size: NText.Size.LabelXs
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Tokens.spaceSm

          NText {
            Layout.fillWidth: true
            text: rowItem.modelData.summary || ""
            color: Colors.surfaceText
            size: NText.Size.BodySm
            font.weight: Font.DemiBold
            elide: Text.ElideRight
          }
          // Message count, and which way the thread folds.
          NText {
            visible: rowItem.count > 1
            text: rowItem.count + (rowItem.open ? "  ▴" : "  ▾")
            color: Colors.primary
            size: NText.Size.LabelXs
          }
        }

        // Folded: the newest message. Open: the whole thread, oldest first.
        NText {
          Layout.fillWidth: true
          visible: !rowItem.open && root.plain(rowItem.latest.body) !== ""
          text: (rowItem.latest.own ? "You: " : "") + root.plain(rowItem.latest.body)
          color: rowItem.latest.own ? Colors.primary : Colors.surfaceTextMuted
          size: NText.Size.BodySm
          wrapMode: Text.WordWrap
          maximumLineCount: 2
          elide: Text.ElideRight
        }
        Repeater {
          model: rowItem.open ? rowItem.modelData.messages.slice().reverse() : []

          delegate: RowLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: Tokens.spaceSm

            NText {
              Layout.fillWidth: true
              text: (modelData.own ? "You: " : "") + root.plain(modelData.body)
              color: modelData.own ? Colors.primary : Colors.surfaceTextMuted
              size: NText.Size.BodySm
              wrapMode: Text.WordWrap
            }
            NText {
              Layout.alignment: Qt.AlignTop
              text: root.relativeTime(modelData.timestamp)
              color: Colors.labelText
              size: NText.Size.LabelXs
            }
          }
        }
      }

      Text {
        id: dismissText
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        text: "×"
        color: Colors.labelText
        font.pixelSize: Tokens.bodyLgSize

        HoverHandler {
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: Notifs.removeConversation(rowItem.modelData.key)
        }
      }
    }
  }
}
