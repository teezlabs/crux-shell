import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Widgets

// Power menu: fullscreen scrim, row of 5 chamfered tiles. Keys L/S/E/R/P select; ←→ move selection; ⏎ confirms.
// All paths go through a confirm step (SessionMenuTab.qml's confirmActions) — no bare single-keypress trigger for destructive actions.
NPanelWindow {
  id: root

  popupName: "power"
  surfaceNamespace: "crux-power-menu"
  // No scrim: the tiles float over the blurred desktop.
  color: "transparent"

  readonly property var actions: [
    {
      "label": "Lock",
      "display": "LOCK",
      "key": "L",
      "tint": "primary",
      // `loginctl lock-session` alone does nothing unless some session-lock
      // client is listening for it — crux now is one (Modules/LockScreen),
      // so trigger it directly over its own IPC target instead.
      "run": ["qs", "ipc", "-c", "crux", "call", "lockscreen", "lock"]
    },
    {
      "label": "Suspend",
      "display": "SUSPEND",
      "key": "S",
      "tint": "",
      "run": ["sh", "-c", "systemctl suspend || loginctl suspend"]
    },
    {
      "label": "Logout",
      "display": "LOG OUT",
      "key": "E",
      "tint": "",
      "run": ["sh", "-c", "hyprctl dispatch hl.dsp.exit()"]
    },
    {
      "label": "Reboot",
      "display": "REBOOT",
      "key": "R",
      "tint": "tertiary",
      "run": ["sh", "-c", "systemctl reboot || loginctl reboot"]
    },
    {
      "label": "Shutdown",
      "display": "SHUTDOWN",
      "key": "P",
      "tint": "error",
      "run": ["sh", "-c", "systemctl poweroff || loginctl poweroff"]
    }
  ]

  readonly property var visibleActions: actions.filter(a => Settings.data.sessionMenu.enabledActions.indexOf(a.label) !== -1)

  property int selectedIndex: 0
  property string armedLabel: ""

  Timer {
    id: armTimer
    interval: Settings.data.sessionMenu.confirmWindowMs
    onTriggered: root.armedLabel = ""
  }

  function activate(action) {
    if (!action)
      return;
    var needsConfirm = Settings.data.sessionMenu.confirmActions.indexOf(action.label) !== -1;
    if (needsConfirm && root.armedLabel !== action.label) {
      root.armedLabel = action.label;
      armTimer.restart();
      return;
    }
    root.visible = false;
    Quickshell.execDetached(action.run);
  }

  onVisibleChanged: {
    if (!visible) {
      armedLabel = "";
    } else {
      selectedIndex = Math.max(0, visibleActions.findIndex(a => a.label === "Lock"));
    }
  }

  Shortcut {
    sequence: "Left"
    enabled: root.visible
    onActivated: root.selectedIndex = Math.max(0, root.selectedIndex - 1)
  }
  Shortcut {
    sequence: "Right"
    enabled: root.visible
    onActivated: root.selectedIndex = Math.min(root.visibleActions.length - 1, root.selectedIndex + 1)
  }
  Shortcut {
    sequence: "Return"
    enabled: root.visible
    onActivated: root.activate(root.visibleActions[root.selectedIndex])
  }
  Instantiator {
    model: root.visibleActions
    Shortcut {
      required property var modelData
      required property int index
      sequence: modelData.key
      enabled: root.visible
      onActivated: {
        root.selectedIndex = index;
        root.activate(modelData);
      }
    }
  }

  // Content-sized backdrop: nearly transparent on purpose, it exists so
  // Hyprland has something to blur behind the tiles.
  Chamfer {
    readonly property int pad: 20
    x: layout.x - pad
    y: layout.y - pad
    width: layout.width + pad * 2
    height: layout.height + pad * 2
    chamferSize: Tokens.chamferPanel
    cutTopRight: true
    cutBottomLeft: true
    fillColor: Colors.alpha(Colors.surface, 0.18)
    // No shadow here: its soft pixels fall outside the shape and, past the
    // low blur threshold this namespace uses, get blurred into a halo.
  }

  ColumnLayout {
    id: layout
    anchors.centerIn: parent
    spacing: 12

    Row {
      Layout.alignment: Qt.AlignHCenter
      spacing: 2

      Repeater {
        model: root.visibleActions

        delegate: Item {
          id: tile
          required property var modelData
          required property int index
          readonly property bool selected: index === root.selectedIndex
          readonly property bool armed: root.armedLabel === modelData.label
          // Only REBOOT/SHUTDOWN carry a permanent tint; others (incl. LOCK) are neutral until selected.
          readonly property bool hasPermanentTint: modelData.tint === "error" || modelData.tint === "tertiary"
          readonly property color permanentTint: modelData.tint === "error" ? Colors.error : Colors.tertiary
          readonly property color accentColor: tile.hasPermanentTint ? tile.permanentTint : Colors.primary

          width: 108
          height: 108

          Chamfer {
            anchors.fill: parent
            chamferSize: 10 // spec §6.9: "each chamfered 10px" (an explicit override of the shared 8-10px tier)
            cutTopRight: true
            cutBottomLeft: true
            // State is carried by fill, not outline: armed reads as error,
            // selected as the tile's own accent.
            fillColor: tile.armed ? Colors.alpha(Colors.error, 0.26) : (tile.selected ? Colors.alpha(tile.accentColor, 0.24) : Colors.alpha(Colors.surfaceContainer, Tokens.barModuleOpacity))
            shadow: true
            shadowBlur: Tokens.shadowBlurCard
            shadowOpacity: Tokens.shadowOpacityCard
            shadowOffset: Tokens.shadowOffsetCard
          }

          Column {
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
              anchors.horizontalCenter: parent.horizontalCenter
              width: 20
              height: 20
              color: "transparent"
              border.color: tile.armed ? Colors.error : (tile.hasPermanentTint ? tile.permanentTint : (tile.selected ? Colors.primary : Colors.labelText))
              border.width: 2
            }

            NText {
              tracking: true
              anchors.horizontalCenter: parent.horizontalCenter
              text: tile.armed ? "CONFIRM?" : tile.modelData.display
              color: tile.armed ? Colors.error : (tile.modelData.tint === "error" ? Colors.error : (tile.selected ? Colors.primary : Colors.surfaceText))
              size: NText.Size.Label
              font.weight: Font.DemiBold
            }

            NText {
              anchors.horizontalCenter: parent.horizontalCenter
              text: tile.modelData.key
              color: Colors.labelText
              size: NText.Size.LabelXs
            }
          }

          HoverHandler {
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: if (hovered)
              root.selectedIndex = tile.index
          }
          TapHandler {
            onTapped: root.activate(tile.modelData)
          }
        }
      }
    }

    NText {
      tracking: true
      Layout.alignment: Qt.AlignHCenter
      text: "←→ SELECT · ⏎ CONFIRM · ESC CANCEL"
      color: Colors.labelText
      size: NText.Size.LabelXs
    }
  }
}
