import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Modules.Bar.Extras

// Power menu (§6.9): fullscreen scrim, row of 5 chamfered tiles (hollow
// square icon, label, single-key hint). LOCK is default-focused
// (primaryContainer fill + accent border), REBOOT's icon is tertiary,
// SHUTDOWN's border/text is error. Keys L/S/E/R/P jump straight to an
// action; ←→ move the keyboard selection; ⏎ confirms.
//
// Deviation from the literal spec: the mockup's key-hints (L/S/E/R/P)
// read as instant single-press triggers, but this project's own earlier
// session explicitly asked for a confirm step on anything destructive
// (SessionMenuTab.qml's confirmActions setting) — kept here uniformly
// across click, letter-key and arrow+Enter, rather than giving Shutdown a
// bare single-keypress trigger the spec's cosmetic mockup didn't actually
// need to defend.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

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
    interval: 2500
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

  function toggle() {
    visible = !visible;
  }

  visible: false
  color: Color.alpha(Color.surface, 0.9)

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-power-menu"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  IpcHandler {
    enabled: root.targetScreen === Quickshell.screens[0]
    target: "power"
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

  MouseArea {
    anchors.fill: parent
    onClicked: root.visible = false
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
          // Spec §6.9: only REBOOT (icon tertiary) and SHUTDOWN (border AND
          // text error) carry a permanent tint, unconditionally, whether
          // selected or not — everything else (including LOCK) is neutral
          // until selected, at which point it takes the generic "accent"
          // selection treatment. Previously every tile defaulted to a
          // "primary" tint even unselected/unarmed (LOCK/SUSPEND/LOGOUT all
          // showed a permanently primary-colored icon/text), which doesn't
          // match "LOCK is default-focused" reading as a one-time initial
          // selection state, not LOCK's own permanent color.
          readonly property bool hasPermanentTint: modelData.tint === "error" || modelData.tint === "tertiary"
          readonly property color permanentTint: modelData.tint === "error" ? Color.error : Color.tertiary
          readonly property color accentColor: tile.hasPermanentTint ? tile.permanentTint : Color.primary

          width: 108
          height: 108

          Chamfer {
            anchors.fill: parent
            chamferSize: 10 // spec §6.9: "each chamfered 10px" (an explicit override of the shared 8-10px tier)
            cutTopRight: true
            cutBottomLeft: true
            // Spec: "LOCK is default-focused: primary_container fill,
            // accent border" — a flat role fill, not an alpha-blended tint.
            fillColor: tile.selected ? Color.primaryContainer : Color.surfaceContainer
            strokeColor: tile.armed ? Color.error : (tile.hasPermanentTint ? tile.permanentTint : (tile.selected ? Color.primary : Color.outline))
            strokeWidth: tile.selected || tile.armed ? 2 : Tokens.borderModule
          }

          Column {
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
              anchors.horizontalCenter: parent.horizontalCenter
              width: 20
              height: 20
              color: "transparent"
              border.color: tile.armed ? Color.error : (tile.hasPermanentTint ? tile.permanentTint : (tile.selected ? Color.primary : Color.labelText))
              border.width: 2
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: tile.armed ? "CONFIRM?" : tile.modelData.display
              color: tile.armed ? Color.error : (tile.modelData.tint === "error" ? Color.error : (tile.selected ? Color.primary : Color.surfaceText))
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelSize
              font.weight: Font.DemiBold
              font.letterSpacing: Tokens.labelSize * Tokens.labelTracking
            }

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              text: tile.modelData.key
              color: Color.labelText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
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

    Text {
      Layout.alignment: Qt.AlignHCenter
      text: "←→ SELECT · ⏎ CONFIRM · ESC CANCEL"
      color: Color.labelText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelXsSize
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
    }
  }
}
