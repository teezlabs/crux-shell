import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Widgets

// One login surface per screen, laid out like the lock screen: clock top-left, power top-right, login bottom-left.
PanelWindow {
  id: surface

  required property var context

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }
  exclusionMode: ExclusionMode.Ignore
  color: Colors.surface
  WlrLayershell.namespace: "crux-greeter"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  property date now: new Date()
  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: surface.now = new Date()
  }

  Image {
    id: wallpaper
    anchors.fill: parent
    source: {
      var custom = Settings.data.lockScreen.useCustomWallpaper && Settings.data.lockScreen.customWallpaperPath;
      var path = custom ? Settings.data.lockScreen.customWallpaperPath : Settings.getWallpaperForScreen(surface.screen ? surface.screen.name : "");
      return path ? "file://" + path : "";
    }
    sourceSize: Qt.size(surface.width, surface.height)
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    visible: false
  }

  MultiEffect {
    anchors.fill: parent
    source: wallpaper
    blurEnabled: true
    blur: Settings.data.lockScreen.blurAmount
    blurMax: 64
    autoPaddingEnabled: false
  }

  Rectangle {
    anchors.fill: parent
    color: Colors.alpha(Colors.surface, Settings.data.lockScreen.dimAmount)
  }

  HoverHandler {
    onHoveredChanged: if (hovered && !passwordInput.activeFocus)
      passwordInput.forceActiveFocus()
  }

  // The preview runs inside a live session, so Escape must always get the user out.
  Shortcut {
    enabled: surface.context.preview
    sequence: "Escape"
    onActivated: Qt.quit()
  }

  Column {
    x: 96
    y: 80
    spacing: 14

    NText {
      tracking: true
      text: Qt.formatDateTime(surface.now, Settings.data.lockScreen.clockFormat)
      color: Colors.surfaceText
      size: NText.Size.Display
    }

    Row {
      spacing: 14

      Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 52
        height: 2
        color: Colors.primary
      }

      NText {
        tracking: true
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(surface.now, Settings.data.lockScreen.dateFormat).toUpperCase()
        color: Colors.labelText
        size: NText.Size.Label
      }
    }
  }

  NText {
    tracking: true
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.margins: 24
    visible: surface.context.preview
    text: "PREVIEW · ESC TO CLOSE"
    color: Colors.tertiary
    size: NText.Size.LabelXs
  }

  // Suspend, restart and shut down, arm-then-confirm like the lock screen.
  property string armedPowerAction: ""
  Timer {
    id: powerArmTimer
    interval: 2500
    onTriggered: surface.armedPowerAction = ""
  }

  Row {
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: 24
    spacing: 8

    Repeater {
      model: [
        {
          "id": "suspend",
          "label": "SUSPEND",
          "confirm": false,
          "run": ["systemctl", "suspend"]
        },
        {
          "id": "reboot",
          "label": "RESTART",
          "confirm": true,
          "run": ["systemctl", "reboot"]
        },
        {
          "id": "power",
          "label": "SHUT DOWN",
          "confirm": true,
          "run": ["systemctl", "poweroff"]
        }
      ]

      delegate: Column {
        id: powerBtn
        required property var modelData
        readonly property bool armed: surface.armedPowerAction === modelData.id
        spacing: 4

        Item {
          anchors.horizontalCenter: parent.horizontalCenter
          width: 26
          height: 26

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: powerBtn.armed ? Colors.alpha(Colors.error, 0.25) : (powerHover.hovered ? Colors.surfaceContainerHigh : "transparent")
            strokeColor: Colors.alpha(Colors.error, powerBtn.armed ? 1 : (powerHover.hovered ? 0.7 : 0.4))
            strokeWidth: Tokens.borderModule
          }

          Canvas {
            anchors.centerIn: parent
            width: 14
            height: 14
            readonly property string kind: powerBtn.modelData.id
            readonly property color drawColor: Colors.error
            onDrawColorChanged: requestPaint()
            onPaint: {
              var ctx = getContext("2d");
              ctx.reset();
              ctx.strokeStyle = drawColor;
              ctx.fillStyle = drawColor;
              ctx.lineWidth = 1.4;
              ctx.lineCap = "round";
              var cx = width / 2, cy = height / 2, top = -Math.PI / 2, gap = 0.7;
              if (kind === "power") {
                ctx.beginPath();
                ctx.arc(cx, cy + 1, 5, top + gap / 2, top - gap / 2 + Math.PI * 2);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(cx, 0);
                ctx.lineTo(cx, 6);
                ctx.stroke();
              } else if (kind === "reboot") {
                ctx.beginPath();
                ctx.arc(cx, cy, 5, Math.PI * 0.15, Math.PI * 1.75);
                ctx.stroke();
                ctx.beginPath();
                ctx.moveTo(cx + 5, cy - 4);
                ctx.lineTo(cx + 6.5, cy - 0.5);
                ctx.lineTo(cx + 2.5, cy - 1.5);
                ctx.closePath();
                ctx.fill();
              } else {
                ctx.beginPath();
                ctx.arc(cx, cy, 5, 0, Math.PI * 2);
                ctx.fill();
                ctx.globalCompositeOperation = "destination-out";
                ctx.beginPath();
                ctx.arc(cx + 3, cy - 2, 4.5, 0, Math.PI * 2);
                ctx.fill();
                ctx.globalCompositeOperation = "source-over";
              }
            }
          }

          HoverHandler {
            id: powerHover
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: {
              if (powerBtn.modelData.confirm && !powerBtn.armed) {
                surface.armedPowerAction = powerBtn.modelData.id;
                powerArmTimer.restart();
                return;
              }
              powerArmTimer.stop();
              surface.armedPowerAction = "";
              if (surface.context.preview)
                surface.context.errorMessage = "PREVIEW — " + powerBtn.modelData.label + " SKIPPED";
              else
                Quickshell.execDetached(powerBtn.modelData.run);
            }
          }
        }

        NText {
          tracking: true
          anchors.horizontalCenter: parent.horizontalCenter
          text: powerBtn.armed ? "CONFIRM?" : powerBtn.modelData.label
          color: Colors.labelText
          font.pixelSize: Tokens.labelXsSize - 2
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
      }
    }
  }

  Column {
    id: login
    x: 96
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 80
    width: 452
    spacing: 12

    // User pills; a single account still shows its name so you know who you're logging in as.
    Row {
      spacing: 6

      Repeater {
        model: surface.context.users

        delegate: Item {
          id: userPill
          required property var modelData
          required property int index
          readonly property bool selected: index === surface.context.userIndex
          width: userLabel.implicitWidth + 24
          height: 26

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: userPill.selected ? Colors.primary : Colors.alpha(Colors.surfaceContainerHigh, userHover.hovered ? 0.9 : 0.6)
            strokeColor: userPill.selected ? Colors.primary : Colors.outline
            strokeWidth: Tokens.borderModule
          }

          NText {
            id: userLabel
            tracking: true
            anchors.centerIn: parent
            text: userPill.modelData.label.toUpperCase()
            color: userPill.selected ? Colors.primaryText : Colors.surfaceText
            size: NText.Size.LabelXs
          }

          HoverHandler {
            id: userHover
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: surface.context.cycleUser(userPill.index - surface.context.userIndex)
          }
        }
      }
    }

    Item {
      id: passwordField
      width: parent.width
      height: 58

      Chamfer {
        anchors.fill: parent
        chamferSize: Tokens.chamferModule
        cutTopRight: true
        cutBottomLeft: true
        fillColor: Colors.alpha(Colors.surface, Tokens.panelOpacity)
        strokeColor: passwordInput.activeFocus ? Colors.primary : Colors.outline
        strokeWidth: Tokens.borderPanel
      }

      Row {
        anchors.left: parent.left
        anchors.right: hint.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16
        anchors.rightMargin: 10
        spacing: 10

        NText {
          text: ">"
          color: Colors.primary
          size: NText.Size.BodyLg
          font.weight: Font.DemiBold
          anchors.verticalCenter: parent.verticalCenter
        }

        TextInput {
          id: passwordInput
          width: parent.width - 40
          anchors.verticalCenter: parent.verticalCenter
          echoMode: surface.context.echoResponse ? TextInput.Normal : TextInput.Password
          passwordCharacter: "•"
          passwordMaskDelay: 0
          enabled: !surface.context.busy
          color: Colors.primary
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodyLgSize
          font.letterSpacing: Tokens.bodyLgSize * 0.4

          onTextChanged: if (surface.context.currentText !== text)
            surface.context.currentText = text
          Connections {
            target: surface.context
            function onCurrentTextChanged() {
              if (passwordInput.text !== surface.context.currentText)
                passwordInput.text = surface.context.currentText;
            }
          }

          Keys.onReturnPressed: surface.context.submit()
          Keys.onEnterPressed: surface.context.submit()
          Keys.onTabPressed: surface.context.cycleUser(1)
          Keys.onUpPressed: surface.context.cycleSession(-1)
          Keys.onDownPressed: surface.context.cycleSession(1)

          Component.onCompleted: forceActiveFocus()

          NText {
            tracking: true
            anchors.verticalCenter: parent.verticalCenter
            visible: passwordInput.text === ""
            text: surface.context.prompt
            color: Colors.disabledText
            size: NText.Size.LabelXs
          }
        }
      }

      NText {
        id: hint
        tracking: true
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: surface.context.busy ? "…" : "⏎ LOGIN"
        color: Colors.labelText
        size: NText.Size.LabelXs
      }
    }

    // Session switcher (↑/↓ in the field, or tap) and the status line.
    Row {
      x: 16
      spacing: 16

      Row {
        spacing: 6

        NText {
          tracking: true
          text: "SESSION"
          color: Colors.labelText
          size: NText.Size.LabelXs
        }
        NText {
          tracking: true
          text: surface.context.session ? surface.context.session.name.toUpperCase() : "NONE FOUND"
          color: surface.context.session ? (sessionHover.hovered ? Colors.primary : Colors.surfaceText) : Colors.error
          size: NText.Size.LabelXs

          HoverHandler {
            id: sessionHover
            cursorShape: surface.context.sessions.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
          }
          TapHandler {
            onTapped: surface.context.cycleSession(1)
          }
        }
      }

      NText {
        tracking: true
        visible: surface.context.errorMessage !== ""
        text: surface.context.errorMessage
        color: Colors.error
        size: NText.Size.LabelXs
      }

      NText {
        tracking: true
        visible: surface.context.errorMessage === "" && surface.context.infoMessage !== ""
        text: surface.context.infoMessage
        color: Colors.labelText
        size: NText.Size.LabelXs
      }

      NText {
        tracking: true
        visible: surface.context.failedAttempts > 0
        text: "ATTEMPTS " + surface.context.failedAttempts
        color: Colors.labelText
        size: NText.Size.LabelXs
      }
    }
  }
}
