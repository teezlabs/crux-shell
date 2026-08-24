import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

// Power menu popup: a row of honeycomb (hexagon) buttons. Separate top-level
// surface since the bar strip itself is too thin to host a dropdown.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  // Lock/Suspend previously used raw emoji glyphs (u{1F512}/u{1F319}) —
  // true emoji need color-font support this box's font stack doesn't have
  // (see crux skill's font gotchas), risking a tofu-box render same as the
  // wifi-icon issue found early on. "geo" glyphs are drawn on Canvas below
  // instead, matching the safe pattern every bar widget already uses.
  readonly property var actions: [
    {
      "label": "Lock",
      "glyph": "geo:lock",
      "run": ["sh", "-c", "loginctl lock-session"]
    },
    {
      "label": "Suspend",
      "glyph": "geo:moon",
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
          id: hexShape
          anchors.fill: parent
          preferredRendererType: Shape.CurveRenderer

          ShapePath {
            strokeColor: Color.mOutline
            strokeWidth: 1
            fillGradient: LinearGradient {
              x1: 0
              y1: 0
              x2: hex.r * 1.733
              y2: hex.r * 2
              GradientStop {
                position: 0
                color: hexMouse.containsMouse ? Qt.lighter(Color.mPrimary, 1.3) : Color.mSurfaceVariant
              }
              GradientStop {
                position: 1
                color: hexMouse.containsMouse ? Color.mPrimary : Color.mSurfaceVariant
              }
            }

            startX: hex.r * 1.733; startY: hex.r * 0.5
            PathLine { x: hex.r * 0.866; y: 0 }
            PathLine { x: 0; y: hex.r * 0.5 }
            PathLine { x: 0; y: hex.r * 1.5 }
            PathLine { x: hex.r * 0.866; y: hex.r * 2 }
            PathLine { x: hex.r * 1.733; y: hex.r * 1.5 }
            PathLine { x: hex.r * 1.733; y: hex.r * 0.5 }
          }
        }

        // Glow when hovered, matching the workspace-pill treatment.
        MultiEffect {
          anchors.fill: hexShape
          source: hexShape
          shadowEnabled: hexMouse.containsMouse
          shadowColor: Color.mPrimary
          shadowBlur: 0.6
          shadowOpacity: 0.7
        }

        Column {
          anchors.centerIn: parent
          spacing: 4

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !hex.modelData.glyph.startsWith("geo:")
            text: hex.modelData.glyph
            font.pixelSize: 20
            color: hexMouse.containsMouse ? Color.mSurface : Color.mOnSurface
          }

          Canvas {
            id: geoIcon
            anchors.horizontalCenter: parent.horizontalCenter
            visible: hex.modelData.glyph.startsWith("geo:")
            width: 18
            height: 18
            readonly property color drawColor: hexMouse.containsMouse ? Color.mSurface : Color.mOnSurface
            onDrawColorChanged: requestPaint()
            onVisibleChanged: if (visible)
              requestPaint()
            onPaint: {
              var ctx = getContext("2d");
              ctx.reset();
              ctx.strokeStyle = drawColor;
              ctx.fillStyle = drawColor;
              ctx.lineWidth = 1.4;
              ctx.lineCap = "round";

              if (hex.modelData.glyph === "geo:lock") {
                // Padlock: shackle arc + body rect.
                ctx.beginPath();
                ctx.arc(9, 7, 4.5, Math.PI, 0, false);
                ctx.stroke();
                ctx.beginPath();
                ctx.roundedRect(3, 7, 12, 9, 2, 2);
                ctx.fill();
              } else if (hex.modelData.glyph === "geo:moon") {
                // Crescent moon via destination-out cutout, matching the
                // Settings gear/PowerButton Canvas pattern.
                ctx.beginPath();
                ctx.arc(9, 9, 7, 0, Math.PI * 2);
                ctx.fill();
                ctx.globalCompositeOperation = "destination-out";
                ctx.beginPath();
                ctx.arc(12.5, 6.5, 6, 0, Math.PI * 2);
                ctx.fill();
              }
            }
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: hex.modelData.label
            font.family: Settings.data.ui.fontFamily
            font.pixelSize: 11
            color: hexMouse.containsMouse ? Color.mSurface : Color.mOnSurface
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
