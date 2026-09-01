import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.Commons
import qs.Modules.Bar.Extras

// Notification history popup: persistent log of past notifications, distinct from NotificationsWindow.qml's live toast stack.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property string _barPos: Settings.isLoaded ? Settings.getBarPositionForScreen(root.targetScreen ? root.targetScreen.name : "") : "top"
  readonly property bool _barLeft: root._barPos === "left"
  readonly property bool _barRight: root._barPos === "right"
  readonly property bool _barBottom: root._barPos === "bottom"
  readonly property real _barOffset: Settings.data.bar.thickness + Settings.data.bar.floatMargin * 2 + 20

  property point triggerPos: Qt.point(-1, -1)
  readonly property bool _hasTrigger: triggerPos.x >= 0
  readonly property real _triggerX: triggerPos.x + Settings.data.bar.floatMargin
  readonly property real _triggerY: triggerPos.y + Settings.data.bar.floatMargin

  readonly property var history: Notifs.history

  // Forces relativeTime() text to re-evaluate periodically — Date.now() reads
  // inside a binding aren't tracked as a dependency on their own.
  property int _tick: 0
  Timer {
    interval: 30000
    running: root.visible
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

  function toggle() {
    visible = !visible;
  }

  IpcHandler {
    enabled: root.targetScreen === Quickshell.screens[0]
    target: "notificationHistory"
    function toggle() {
      root.toggle();
    }
    function open() {
      if (!root.visible)
        root.toggle();
    }
    function close() {
      root.visible = false;
    }
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
  WlrLayershell.namespace: "crux-notification-history"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

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

    readonly property real _crossFallback: 12
    readonly property real _crossPos: {
      if (root._barLeft || root._barRight)
        return root._hasTrigger ? Math.max(8, Math.min(root._triggerY, root.height - card.height - 8)) : _crossFallback;
      return root._hasTrigger ? Math.max(8, Math.min(root._triggerX, root.width - card.width - 8)) : root.width - card.width - _crossFallback;
    }

    x: root._barLeft ? root._barOffset : (root._barRight ? root.width - card.width - root._barOffset : card._crossPos)
    y: root._barBottom ? root.height - card.height - root._barOffset : (root._barLeft || root._barRight ? card._crossPos : root._barOffset)
    width: 380
    height: Math.min(520, column.implicitHeight + 24)

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutTopRight: true
      cutBottomLeft: true
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
      anchors.fill: parent
      anchors.margins: 14
      spacing: 10

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
  }
}
