import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import qs.Commons
import qs.Modules.Bar.Extras

// Sidebar Dashboard (§6.8): 388 wide, full height, left-anchored, slides in.
// Sections: Clock, Now Playing, Notifications, Workspaces. Every section
// reuses the same real data sources already wired for the bar/popups —
// Hyprland for workspaces, Mpris for Now Playing, Notifs for the
// notification list — nothing here is fabricated. Workspace "previews" are
// occupied/active chips, not actual window thumbnails: Quickshell exposes
// no live per-workspace screenshot source, so a real 16:9 image preview
// would have to be faked — the spec's slot is filled honestly instead.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property var players: Mpris.players ? Mpris.players.values : []
  readonly property var activePlayer: {
    for (var i = 0; i < players.length; i++) {
      if (players[i] && players[i].playbackState === MprisPlaybackState.Playing)
        return players[i];
    }
    return players.length > 0 ? players[0] : null;
  }
  readonly property bool isPlaying: activePlayer ? activePlayer.playbackState === MprisPlaybackState.Playing : false

  property int _positionTick: 0
  readonly property real position: {
    _positionTick;
    return activePlayer ? activePlayer.position : 0;
  }
  readonly property real length: activePlayer ? activePlayer.length : 0

  Timer {
    interval: 1000
    running: root.visible && root.isPlaying
    repeat: true
    onTriggered: root._positionTick++
  }

  function fmtTime(seconds) {
    if (!seconds || seconds < 0)
      return "0:00";
    var m = Math.floor(seconds / 60);
    var s = Math.floor(seconds % 60);
    return m + ":" + String(s).padStart(2, "0");
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
    // 24-hour, matching the bar clock's own "14:32" example in spec §6.1 —
    // no reason for the sidebar to be the one 12-hour clock in the app.
    return Qt.formatDateTime(new Date(), "HH:mm");
  }
  function dateLabel() {
    // Spec §6.8 exact format: "WEDNESDAY 25 AUGUST" (day-name day month, no
    // year, no comma) — rendered uppercase at the call site per §2's "all
    // label-tier text is uppercase" rule.
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

  visible: false
  color: "transparent"

  anchors {
    top: true
    left: true
    bottom: true
  }
  implicitWidth: 388

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-sidebar"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  IpcHandler {
    enabled: root.targetScreen === Quickshell.screens[0]
    target: "sidebar"
    function toggle() {
      root.toggle();
    }
    function open() {
      root.visible = true;
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
      color: Color.alpha(Color.surface, Tokens.panelOpacity)
      border.color: Color.outline
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
        Text {
          text: root._clockNow
          color: Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.titleSize
          font.weight: Font.ExtraLight
          font.letterSpacing: Tokens.titleSize * Tokens.titleTracking
        }
        Text {
          text: root._clockDate.toUpperCase()
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: Tokens.borderDivider
        color: Color.surfaceContainerHigh
      }

      // Now Playing
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 8
        visible: !!root.activePlayer

        Text {
          text: "NOW PLAYING"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
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
              fillColor: Color.surfaceContainer
              strokeColor: Color.outline
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
                ctx.strokeStyle = Color.surfaceContainerHigh;
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
            Text {
              Layout.fillWidth: true
              text: root.activePlayer ? root.activePlayer.trackTitle : ""
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySize
              font.weight: Font.DemiBold
              elide: Text.ElideRight
            }
            Text {
              Layout.fillWidth: true
              text: root.activePlayer ? root.activePlayer.trackArtist : ""
              color: Color.surfaceTextMuted
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
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
          filledColor: Color.primary
          emptyColor: Color.surfaceContainerHigh
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
        color: Color.surfaceContainerHigh
      }

      // Notifications
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "NOTIFICATIONS"
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }
          Item {
            Layout.fillWidth: true
          }
          Text {
            visible: root.notifications.length > 0
            text: "CLEAR"
            color: Color.primary
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking

            HoverHandler {
              cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
              onTapped: Notifs.clearAll()
            }
          }
        }

        Text {
          visible: root.notifications.length === 0
          text: "NO NOTIFICATIONS"
          color: Color.disabledText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySmSize
        }

        Repeater {
          model: root.recentNotifications

          // Spec §6.8 explicitly wants "compact single-line cards" here —
          // distinct from the full Notifications popover's richer
          // summary+body layout (NotificationsWindow.qml), which is the
          // right place for the fuller treatment.
          delegate: Item {
            id: card
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredHeight: 24

            readonly property color urgencyColor: modelData.urgency === NotificationUrgency.Critical ? Color.primary : (modelData.urgency === NotificationUrgency.Low ? Color.outline : Color.tertiary)

            Rectangle {
              anchors.fill: parent
              color: Color.surfaceContainer
            }
            Rectangle {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.bottom: parent.bottom
              width: 2
              color: card.urgencyColor
            }
            Text {
              anchors.fill: parent
              anchors.margins: 6
              anchors.leftMargin: 12
              verticalAlignment: Text.AlignVCenter
              text: card.modelData.summary || ""
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
              elide: Text.ElideRight
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: Tokens.borderDivider
        color: Color.surfaceContainerHigh
      }

      // Workspaces — 5-up previews. No live window-thumbnail source exists
      // via Quickshell, so each slot is an honest occupied/active chip
      // (16:9 aspect) rather than a fabricated screenshot.
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: "WORKSPACES"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
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

              // Spec §6.8: "active gets primary_container + 2px primary
              // bottom border" — a flat fill plus an underline, not the
              // full-outline treatment other selected states in the app use.
              Chamfer {
                anchors.fill: parent
                chamferSize: Tokens.chamferIcon
                cutTopRight: true
                cutBottomLeft: true
                fillColor: cell.modelData.active ? Color.primaryContainer : Color.surfaceContainer
                strokeColor: Color.outlineVariant
                strokeWidth: Tokens.borderModule
              }
              Rectangle {
                visible: cell.modelData.active
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 2
                color: Color.primary
              }

              Text {
                anchors.centerIn: parent
                text: String(cell.modelData.wsId)
                color: cell.modelData.active ? Color.primaryContainerText : (cell.modelData.occupied ? Color.surfaceText : Color.disabledText)
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.bodySize
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
