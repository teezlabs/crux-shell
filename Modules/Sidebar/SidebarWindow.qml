import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import qs.Commons
import qs.Modules.Notifications
import qs.Widgets
import qs.Services

// Sidebar Dashboard: Clock/Now Playing/Notifications/Workspaces, all real data. Workspace "previews" are occupied/active chips, not thumbnails (no live screenshot source).
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  // Direct in-process handle for callers on this screen (see Commons/Popups.qml).
  PopupRegistration {
    name: "sidebar"
    surface: root
    screen: root.targetScreen
  }

  readonly property var activePlayer: MediaService.activePlayer
  readonly property bool isPlaying: MediaService.isPlaying
  readonly property real position: MediaService.position
  readonly property real length: MediaService.length

  function fmtTime(seconds) {
    return MediaService.fmtTime(seconds);
  }

  property var wsModel: []

  function refreshWorkspaces() {
    var values = Hyprland.workspaces && Hyprland.workspaces.values ? Hyprland.workspaces.values : [];
    var occupied = {};
    var focusedId = -1;
    var screenName = root.targetScreen ? root.targetScreen.name : "";
    for (var i = 0; i < values.length; i++) {
      var ws = values[i];
      if (!ws || (ws.name && ws.name.indexOf("special:") === 0))
        continue;
      var monitorName = ws.monitor && ws.monitor.name ? ws.monitor.name : "";
      if (monitorName.toLowerCase() !== screenName.toLowerCase())
        continue;
      occupied[ws.id] = true;
      if (ws.focused === true)
        focusedId = ws.id;
    }
    var list = [];
    for (var n = 1; n <= 5; n++) {
      list.push({
        "wsId": n,
        "occupied": !!occupied[n],
        "active": n === focusedId
      });
    }
    root.wsModel = list;
  }

  Component.onCompleted: {
    Hyprland.refreshWorkspaces();
    Qt.callLater(refreshWorkspaces);
  }
  Connections {
    target: Hyprland.workspaces
    function onValuesChanged() {
      Qt.callLater(root.refreshWorkspaces);
    }
  }
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      Hyprland.refreshWorkspaces();
      Qt.callLater(root.refreshWorkspaces);
    }
  }

  readonly property var notifications: Notifs.notifications
  readonly property var recentNotifications: notifications.slice(0, 4)

  function nowLabel() {
    // 24-hour, matching the bar clock (spec §6.1).
    return Qt.formatDateTime(new Date(), "HH:mm");
  }
  function dateLabel() {
    // Spec §6.8: "WEDNESDAY 25 AUGUST", uppercased at the call site.
    return Qt.formatDateTime(new Date(), "dddd d MMMM");
  }
  property string _clockNow: nowLabel()
  property string _clockDate: dateLabel()
  Timer {
    interval: 1000
    running: root.visible
    repeat: true
    onTriggered: {
      root._clockNow = root.nowLabel();
      root._clockDate = root.dateLabel();
    }
  }

  function toggle() {
    visible = !visible;
  }
  function open() {
    visible = true;
  }
  function close() {
    visible = false;
  }

  visible: false
  color: "transparent"

  // Closes on a click outside it, on any monitor.
  HyprlandFocusGrab {
    active: root.visible
    windows: [root]
    onCleared: Popups.closeAll()
  }

  anchors {
    top: true
    left: true
    bottom: true
  }
  implicitWidth: 388

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-sidebar"
  WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.visible = false
  }

  Item {
    id: slide
    anchors.fill: parent
    x: root.visible ? 0 : -width
    Behavior on x {
      NumberAnimation {
        duration: Tokens.durationSidebarSlide
        easing.type: Tokens.easingSidebarSlide
      }
    }

    Rectangle {
      anchors.fill: parent
      color: Colors.alpha(Colors.surface, Tokens.panelOpacity)
      border.color: Colors.outline
      border.width: Tokens.borderPanel
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 20
      anchors.topMargin: 28
      spacing: 22

      // Clock
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        NText {
          tracking: true
          text: root._clockNow
          color: Colors.surfaceText
          size: NText.Size.Title
          font.weight: Font.ExtraLight
        }
        NText {
          tracking: true
          text: root._clockDate.toUpperCase()
          color: Colors.labelText
          size: NText.Size.LabelXs
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: Tokens.borderDivider
        color: Colors.surfaceContainerHigh
      }

      // Now Playing
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 8
        visible: !!root.activePlayer

        NText {
          tracking: true
          text: "NOW PLAYING"
          color: Colors.labelText
          size: NText.Size.LabelXs
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          Item {
            Layout.preferredWidth: 66
            Layout.preferredHeight: 66

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferModule
              cutTopRight: true
              cutBottomLeft: true
              fillColor: Colors.surfaceContainer
              strokeColor: Colors.outline
              strokeWidth: Tokens.borderModule
            }

            Image {
              anchors.fill: parent
              anchors.margins: Tokens.borderModule
              visible: root.activePlayer && root.activePlayer.trackArtUrl !== ""
              source: root.activePlayer ? root.activePlayer.trackArtUrl : ""
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
            }

            Canvas {
              anchors.fill: parent
              anchors.margins: Tokens.borderModule
              visible: !root.activePlayer || root.activePlayer.trackArtUrl === ""
              onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = Colors.surfaceContainerHigh;
                ctx.lineWidth = 2;
                for (var x = -height; x < width; x += 8) {
                  ctx.beginPath();
                  ctx.moveTo(x, 0);
                  ctx.lineTo(x + height, height);
                  ctx.stroke();
                }
              }
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            NText {
              Layout.fillWidth: true
              text: root.activePlayer ? root.activePlayer.trackTitle : ""
              color: Colors.surfaceText
              font.weight: Font.DemiBold
              elide: Text.ElideRight
            }
            NText {
              Layout.fillWidth: true
              text: root.activePlayer ? root.activePlayer.trackArtist : ""
              color: Colors.surfaceTextMuted
              size: NText.Size.BodySm
              elide: Text.ElideRight
            }
          }
        }

        SegMeter {
          Layout.fillWidth: true
          cellCount: Tokens.meterSidebarSeekCells
          cellHeight: Tokens.meterSidebarSeekCellHeight
          value: root.length > 0 ? (root.position / root.length) * 100 : 0
          interactive: !!root.activePlayer && root.activePlayer.canSeek
          filledColor: Colors.primary
          emptyColor: Colors.surfaceContainerHigh
          onMoved: pct => {
            if (root.activePlayer && root.activePlayer.canSeek)
              root.activePlayer.position = (pct / 100) * root.length;
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 1

          MpTransportButton {
            Layout.fillWidth: true
            glyph: "⏮"
            available: !!root.activePlayer && root.activePlayer.canGoPrevious
            onTapped: root.activePlayer.previous()
          }
          MpTransportButton {
            Layout.fillWidth: true
            glyph: root.isPlaying ? "⏸" : "▶"
            active: root.isPlaying
            available: !!root.activePlayer && (root.activePlayer.canPlay || root.activePlayer.canPause)
            onTapped: root.activePlayer.togglePlaying()
          }
          MpTransportButton {
            Layout.fillWidth: true
            glyph: "⏭"
            available: !!root.activePlayer && root.activePlayer.canGoNext
            onTapped: root.activePlayer.next()
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: Tokens.borderDivider
        color: Colors.surfaceContainerHigh
      }

      // Notifications
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
          Layout.fillWidth: true
          NText {
            tracking: true
            text: "NOTIFICATIONS"
            color: Colors.labelText
            size: NText.Size.LabelXs
          }
          Item {
            Layout.fillWidth: true
          }
          NText {
            tracking: true
            visible: root.notifications.length > 0
            text: "CLEAR"
            color: Colors.primary
            size: NText.Size.LabelXs

            HoverHandler {
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: Notifs.clearAll()
            }
          }
        }

        NText {
          visible: root.notifications.length === 0
          text: "NO NOTIFICATIONS"
          color: Colors.disabledText
          size: NText.Size.BodySm
        }

        Repeater {
          model: root.recentNotifications

          // Compact single-line cards per spec §6.8.
          delegate: Item {
            id: card
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredHeight: 24

            readonly property color urgencyColor: modelData.urgency === NotificationUrgency.Critical ? Colors.primary : (modelData.urgency === NotificationUrgency.Low ? Colors.outline : Colors.tertiary)

            Rectangle {
              anchors.fill: parent
              color: Colors.surfaceContainer
            }
            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: 2
              color: card.urgencyColor
            }
            NText {
              anchors.fill: parent
              anchors.margins: 6
              anchors.leftMargin: 12
              verticalAlignment: Text.AlignVCenter
              text: card.modelData.summary || ""
              color: Colors.surfaceText
              size: NText.Size.BodySm
              elide: Text.ElideRight
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: Tokens.borderDivider
        color: Colors.surfaceContainerHigh
      }

      // Workspace chips, not thumbnails: Quickshell has no live window-thumbnail source.
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        NText {
          tracking: true
          text: "WORKSPACES"
          color: Colors.labelText
          size: NText.Size.LabelXs
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 2

          Repeater {
            model: root.wsModel

            delegate: Item {
              id: cell
              required property var modelData
              Layout.fillWidth: true
              Layout.preferredHeight: (root.width - 40 - 24) / 5 * 9 / 16

              // Spec §6.8: active gets a primary_container fill and a 2px primary underline.
              Chamfer {
                anchors.fill: parent
                chamferSize: Tokens.chamferIcon
                cutTopRight: true
                cutBottomLeft: true
                fillColor: cell.modelData.active ? Colors.primaryContainer : Colors.surfaceContainer
                strokeColor: Colors.outlineVariant
                strokeWidth: Tokens.borderModule
              }
              Rectangle {
                visible: cell.modelData.active
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 2
                color: Colors.primary
              }

              NText {
                anchors.centerIn: parent
                text: String(cell.modelData.wsId)
                color: cell.modelData.active ? Colors.primaryContainerText : (cell.modelData.occupied ? Colors.surfaceText : Colors.disabledText)
              }

              HoverHandler {
                cursorShape: Qt.PointingHandCursor
              }
              TapHandler {
                onTapped: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + cell.modelData.wsId + " })"])
              }
            }
          }
        }
      }

      Item {
        Layout.fillHeight: true
      }
    }
  }
}
