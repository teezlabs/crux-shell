import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

// Power menu popup: a row of honeycomb (hexagon) buttons. Separate top-level
// surface since the bar strip itself is too thin to host a dropdown.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property var actions: [
    {
      "label": "Lock",
      "glyph": "\u{1F512}",
      "run": ["sh", "-c", "loginctl lock-session"]
    },
    {
      "label": "Suspend",
      "glyph": "\u{1F319}",
      "run": ["sh", "-c", "systemctl suspend || loginctl suspend"]
    },
    {
      "label": "Logout",
      "glyph": "⏏",
      "run": ["sh", "-c", "hyprctl dispatch hl.dsp.exit()"]
    },
    {
      "label": "Reboot",
      "glyph": "↻",
      "run": ["sh", "-c", "systemctl reboot || loginctl reboot"]
    },
    {
      "label": "Shutdown",
      "glyph": "⏻",
      "run": ["sh", "-c", "systemctl poweroff || loginctl poweroff"]
    }
  ]

  visible: false
  color: "transparent"

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

  function toggle() {
    visible = !visible;
  }

  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.visible = false
  }

  // Click outside the row closes the menu.
  MouseArea {
    anchors.fill: parent
    onClicked: root.visible = false
  }

  Row {
    anchors.centerIn: parent
    spacing: 0

    Repeater {
      model: root.actions

      delegate: Item {
        id: hex
        required property var modelData

        readonly property real r: 46
        width: r * 1.733
        height: r * 2

        Shape {
          anchors.fill: parent
          preferredRendererType: Shape.CurveRenderer

          ShapePath {
            fillColor: hexMouse.containsMouse ? "#89b4fa" : "#313244"
            strokeColor: "#45475a"
            strokeWidth: 1

            startX: hex.r * 1.733; startY: hex.r * 0.5
            PathLine { x: hex.r * 0.866; y: 0 }
            PathLine { x: 0; y: hex.r * 0.5 }
            PathLine { x: 0; y: hex.r * 1.5 }
            PathLine { x: hex.r * 0.866; y: hex.r * 2 }
            PathLine { x: hex.r * 1.733; y: hex.r * 1.5 }
            PathLine { x: hex.r * 1.733; y: hex.r * 0.5 }
          }
        }

        Column {
          anchors.centerIn: parent
          spacing: 4

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: hex.modelData.glyph
            font.pixelSize: 20
            color: hexMouse.containsMouse ? "#1e1e2e" : "#cdd6f4"
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: hex.modelData.label
            font.pixelSize: 11
            color: hexMouse.containsMouse ? "#1e1e2e" : "#cdd6f4"
          }
        }

        MouseArea {
          id: hexMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            Quickshell.execDetached(hex.modelData.run);
            root.visible = false;
          }
        }
      }
    }
  }
}
