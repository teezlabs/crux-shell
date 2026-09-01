import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Networking
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.LockScreen

// Spec §6.10: fullscreen blurred wallpaper, clock top-left, password field
// bottom-left, NET/BAT/VOL top-right, notification summaries bottom-right.
// Single WlSessionLock instantiates its `surface` per screen automatically.
// Real ext-session-lock-v1 lock (same protocol swaylock uses), not a popup.
Loader {
  id: root
  active: false

  property int failedAttempts: 0
  property bool lockedOut: false
  property int lockoutRemaining: 0
  onActiveChanged: if (active) {
    failedAttempts = 0;
    lockedOut = false;
  }

  // Delays the actual lock engagement — e.g. "give me a few seconds after
  // hitting the keybind before the screen really locks".
  function lock() {
    var grace = Settings.data.lockScreen.gracePeriodSec;
    if (grace > 0) {
      graceTimer.interval = grace * 1000;
      graceTimer.restart();
    } else {
      root.active = true;
    }
  }

  Timer {
    id: graceTimer
    repeat: false
    onTriggered: root.active = true
  }

  // crux's own UI-level lockout (disables the password field for a bit
  // after too many failures) — unrelated to and doesn't touch pam_faillock
  // at the OS level, since it never attempts auth itself.
  Timer {
    id: lockoutTimer
    interval: 1000
    repeat: true
    running: root.lockedOut
    onTriggered: {
      root.lockoutRemaining -= 1;
      if (root.lockoutRemaining <= 0) {
        root.lockedOut = false;
        root.failedAttempts = 0;
      }
    }
  }

  // Only unloads once the surface has actually unlocked — see
  // LockContext.onUnlocked below. There's no exposed IPC "unlock": the
  // only path to leaving this screen unauthenticated would defeat the
  // point of a lock screen.
  Timer {
    id: unloadTimer
    interval: 200
    onTriggered: root.active = false
  }

  // Single global instance (unlike the bar's per-screen popups) — no
  // enabled gate needed, there's only ever one of these registering.
  IpcHandler {
    target: "lockscreen"
    function lock(): void {
      root.lock();
    }
  }

  sourceComponent: Component {
    Item {
      LockContext {
        id: lockContext
        onUnlocked: {
          lockSession.locked = false;
          unloadTimer.restart();
          lockContext.currentText = "";
        }
        onFailed: {
          lockContext.currentText = "";
          root.failedAttempts += 1;
          var max = Settings.data.lockScreen.maxFailedAttempts;
          if (max > 0 && root.failedAttempts >= max) {
            root.lockedOut = true;
            root.lockoutRemaining = Settings.data.lockScreen.lockoutDurationSec;
          }
        }
      }

      WlSessionLock {
        id: lockSession
        locked: root.active

        WlSessionLockSurface {
          id: surface

          readonly property var wifiDevice: {
            var devices = Networking.devices ? Networking.devices.values : [];
            for (var i = 0; i < devices.length; i++)
              if (devices[i] && devices[i].type === DeviceType.Wifi)
                return devices[i];
            return null;
          }
          readonly property bool wifiConnected: {
            var networks = wifiDevice && wifiDevice.networks ? wifiDevice.networks.values : [];
            for (var i = 0; i < networks.length; i++)
              if (networks[i] && networks[i].connected)
                return true;
            return false;
          }
          readonly property string netLabel: !Networking.wifiEnabled ? "OFF" : (wifiConnected ? "WLAN" : "SRCH")

          // Password field stays visible/interactable on every monitor
          // regardless (auth must always be reachable) — this only gates
          // the informational chrome (clock/status/power/notifications).
          readonly property bool shownHere: Settings.data.lockScreen.monitors.length === 0 || Settings.data.lockScreen.monitors.includes(surface.screen.name)

          readonly property var sink: Pipewire.ready ? Pipewire.defaultAudioSink : null
          readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
          readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

          PwObjectTracker {
            objects: surface.sink ? [surface.sink] : []
          }

          property bool hasBattery: false
          property int batteryPercent: 0

          Process {
            id: batProc
            command: ["sh", "-c", "cat /sys/class/power_supply/*/capacity 2>/dev/null | head -1"]
            stdout: StdioCollector {
              id: batCollector
              waitForEnd: true
            }
            onExited: {
              var text = batCollector.text.trim();
              surface.hasBattery = text !== "";
              surface.batteryPercent = parseInt(text) || 0;
            }
          }

          Timer {
            interval: 20000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: batProc.running = true
          }

          property bool capsLockOn: false

          Process {
            id: capsProc
            command: ["sh", "-c", "cat /sys/class/leds/*capslock*/brightness 2>/dev/null | head -1"]
            stdout: StdioCollector {
              id: capsCollector
              waitForEnd: true
            }
            onExited: surface.capsLockOn = capsCollector.text.trim() !== "0" && capsCollector.text.trim() !== ""
          }

          Timer {
            interval: 500
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: capsProc.running = true
          }

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
              var path = custom ? Settings.data.lockScreen.customWallpaperPath : Settings.data.wallpaper.path;
              return path ? "file://" + path : "";
            }
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            visible: false
          }

          MultiEffect {
            anchors.fill: parent
            source: wallpaper
            blurEnabled: true
            blur: Settings.data.lockScreen.blurAmount
            blurMax: 64
            // Off — default true bled a soft glow ring past the screen edge.
            autoPaddingEnabled: false
          }

          Rectangle {
            // Darkens the blurred wallpaper enough that on_surface text stays
            // legible regardless of the source image's own brightness.
            anchors.fill: parent
            color: Color.alpha(Color.surface, Settings.data.lockScreen.dimAmount)
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: if (!passwordInput.activeFocus)
              passwordInput.forceActiveFocus()
          }

          // Clock — spec: 132px weight 200 at (96, 80); 52x2 primary rule;
          // "WEDNESDAY 25 AUGUST 2026" at 14px / 0.26em tracking below it.
          Column {
            x: 96
            y: 80
            spacing: 14
            visible: surface.shownHere

            Text {
              text: Qt.formatDateTime(surface.now, Settings.data.lockScreen.clockFormat)
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.displaySize
              font.weight: Tokens.displayWeight
              font.letterSpacing: Tokens.displaySize * Tokens.displayTracking
            }

            Row {
              spacing: 14

              Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 52
                height: 2
                color: Color.primary
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(surface.now, Settings.data.lockScreen.dateFormat).toUpperCase()
                color: Color.labelText
                font.family: Tokens.fontFamily
                font.pixelSize: 14
                font.letterSpacing: 14 * 0.26
              }
            }
          }

          // Top-right status: NET / BAT / VOL
          Row {
            id: statusRow
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 24
            spacing: 16
            visible: surface.shownHere

            Row {
              spacing: 6
              visible: Settings.data.lockScreen.showNetwork
              Text {
                text: "NET"
                color: Color.labelText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.labelSize
                font.weight: Font.Medium
                font.letterSpacing: Tokens.labelSize * Tokens.labelTracking
              }
              Text {
                text: surface.netLabel
                color: Networking.wifiEnabled ? Color.surfaceText : Color.disabledText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.captionSize
              }
            }

            Row {
              visible: Settings.data.lockScreen.showBattery && surface.hasBattery
              spacing: 6
              Text {
                text: "BAT"
                color: Color.labelText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.labelSize
                font.weight: Font.Medium
                font.letterSpacing: Tokens.labelSize * Tokens.labelTracking
              }
              Text {
                text: surface.batteryPercent
                color: Color.surfaceText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.captionSize
              }
            }

            Row {
              spacing: 6
              visible: Settings.data.lockScreen.showVolume
              Text {
                text: "VOL"
                color: Color.labelText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.labelSize
                font.weight: Font.Medium
                font.letterSpacing: Tokens.labelSize * Tokens.labelTracking
              }
              Text {
                text: surface.muted ? "—" : String(Math.round(surface.volume * 100))
                color: surface.muted ? Color.error : Color.surfaceText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.captionSize
              }
            }
          }

          // Power options: Suspend/Reboot/Shutdown, arm-then-confirm like
          // PowerMenuWindow.qml. No Logout/Lock entry — redundant here.
          property string armedPowerAction: ""
          Timer {
            id: powerArmTimer
            interval: 2500
            onTriggered: surface.armedPowerAction = ""
          }

          Row {
            anchors.top: statusRow.bottom
            anchors.topMargin: 14
            anchors.right: parent.right
            anchors.margins: 24
            spacing: 8
            visible: surface.shownHere

            Repeater {
              model: [
                {
                  "id": "suspend",
                  "label": "SUSPEND",
                  "confirm": false,
                  "run": ["sh", "-c", "systemctl suspend || loginctl suspend"]
                },
                {
                  "id": "reboot",
                  "label": "RESTART",
                  "confirm": true,
                  "run": ["sh", "-c", "systemctl reboot || loginctl reboot"]
                },
                {
                  "id": "power",
                  "label": "SHUT DOWN",
                  "confirm": true,
                  "run": ["sh", "-c", "systemctl poweroff || loginctl poweroff"]
                }
              ]

              delegate: Column {
                id: powerBtn
                required property var modelData
                readonly property bool armed: surface.armedPowerAction === modelData.id
                spacing: 4

                Item {
                  id: iconTile
                  anchors.horizontalCenter: parent.horizontalCenter
                  width: 26
                  height: 26

                  Chamfer {
                    anchors.fill: parent
                    chamferSize: Tokens.chamferIcon
                    cutTopRight: true
                    cutBottomLeft: true
                    fillColor: powerBtn.armed ? Color.alpha(Color.error, 0.25) : (powerMouse.containsMouse ? Color.surfaceContainerHigh : "transparent")
                    strokeColor: Color.alpha(Color.error, powerBtn.armed ? 1 : (powerMouse.containsMouse ? 0.7 : 0.4))
                    strokeWidth: Tokens.borderModule
                  }

                  Canvas {
                    id: glyphCanvas
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    property string kind: powerBtn.modelData.id
                    readonly property color drawColor: Color.error
                    onDrawColorChanged: requestPaint()
                    onPaint: {
                      var ctx = getContext("2d");
                      ctx.reset();
                      ctx.strokeStyle = drawColor;
                      ctx.lineWidth = 1.4;
                      ctx.lineCap = "round";
                      var cx = width / 2, cy = height / 2;
                      var top = -Math.PI / 2;
                      var gap = 0.7;
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
                        ctx.fillStyle = drawColor;
                        ctx.fill();
                      } else {
                        ctx.beginPath();
                        ctx.arc(cx, cy, 5, 0, Math.PI * 2);
                        ctx.fillStyle = drawColor;
                        ctx.fill();
                        ctx.globalCompositeOperation = "destination-out";
                        ctx.beginPath();
                        ctx.arc(cx + 3, cy - 2, 4.5, 0, Math.PI * 2);
                        ctx.fillStyle = "#000000";
                        ctx.fill();
                        ctx.globalCompositeOperation = "source-over";
                      }
                    }
                  }

                  MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (powerBtn.modelData.confirm && surface.armedPowerAction !== powerBtn.modelData.id) {
                        surface.armedPowerAction = powerBtn.modelData.id;
                        powerArmTimer.restart();
                        return;
                      }
                      powerArmTimer.stop();
                      surface.armedPowerAction = "";
                      Quickshell.execDetached(powerBtn.modelData.run);
                    }
                  }
                }

                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: powerBtn.armed ? "CONFIRM?" : powerBtn.modelData.label
                  color: Color.labelText
                  font.family: Tokens.fontFamily
                  font.pixelSize: Tokens.labelXsSize - 2
                  font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
                }
              }
            }
          }

          // Password field — bottom-left, 452x58.
          Item {
            id: passwordField
            x: 96
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 80
            width: 452
            height: 58

            Chamfer {
              anchors.fill: parent
              chamferSize: Tokens.chamferModule
              cutTopRight: true
              cutBottomLeft: true
              fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
              strokeColor: Color.outline
              strokeWidth: Tokens.borderPanel
            }

            Row {
              anchors.left: parent.left
              anchors.right: hint.left
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: 16
              anchors.rightMargin: 10
              spacing: 10

              Text {
                text: ">"
                color: Color.primary
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.bodyLgSize
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
              }

              TextInput {
                id: passwordInput
                width: parent.width - 40
                anchors.verticalCenter: parent.verticalCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                passwordMaskDelay: 0
                enabled: !lockContext.unlockInProgress && !root.lockedOut
                color: Color.primary
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.bodyLgSize
                font.letterSpacing: Tokens.bodyLgSize * 0.4
                selectByMouse: true

                onTextChanged: if (lockContext.currentText !== text)
                  lockContext.currentText = text
                Connections {
                  target: lockContext
                  function onCurrentTextChanged() {
                    if (passwordInput.text !== lockContext.currentText)
                      passwordInput.text = lockContext.currentText;
                  }
                }

                Keys.onReturnPressed: lockContext.tryUnlock()
                Keys.onEnterPressed: lockContext.tryUnlock()

                Component.onCompleted: forceActiveFocus()
              }
            }

            Text {
              id: hint
              anchors.right: parent.right
              anchors.rightMargin: 16
              anchors.verticalCenter: parent.verticalCenter
              text: "⏎ UNLOCK"
              color: Color.labelText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
              font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
            }
          }

          // Status line below the password field: caps-lock state, attempts.
          Row {
            x: passwordField.x + 16
            anchors.top: passwordField.bottom
            anchors.topMargin: 8
            spacing: 16

            Text {
              visible: surface.capsLockOn
              text: "CAPS LOCK ON"
              color: Color.error
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
              font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
            }

            Text {
              visible: lockContext.showFailure
              text: lockContext.errorMessage || "AUTHENTICATION FAILED"
              color: Color.error
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
              font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
            }

            Text {
              visible: root.lockedOut
              text: "LOCKED OUT — TRY AGAIN IN " + root.lockoutRemaining + "s"
              color: Color.error
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
              font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
            }

            Text {
              visible: !root.lockedOut && root.failedAttempts > 0
              text: "ATTEMPTS " + root.failedAttempts
              color: Color.labelText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
              font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
            }
          }

          // Notification summaries — bottom-right, 400 wide, 2px gaps, left
          // urgency border. Real Notifs.qml data (§ crux skill: "not a
          // stub"), not a lock-screen-only mock list.
          Column {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: 24
            spacing: 2
            width: 400
            visible: surface.shownHere && Settings.data.lockScreen.showNotifications

            Repeater {
              model: Notifs.notifications.slice(-4)

              delegate: Item {
                id: card
                required property var modelData
                width: 400
                height: cardCol.implicitHeight + 16

                readonly property color urgencyColor: modelData.urgency === 2 ? Color.primary : (modelData.urgency === 0 ? Color.outline : Color.tertiary)

                Rectangle {
                  anchors.fill: parent
                  color: Color.alpha(Color.surfaceContainer, 0.94)
                  border.color: Color.outlineVariant
                  border.width: Tokens.borderPanel
                }
                Rectangle {
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  width: Tokens.borderMarker
                  color: card.urgencyColor
                }

                Column {
                  id: cardCol
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: 14
                  anchors.rightMargin: 14
                  spacing: 2

                  Text {
                    text: (card.modelData.appName || "").toUpperCase()
                    color: Color.labelText
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.labelXsSize
                    font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
                  }
                  Text {
                    width: parent.width
                    text: card.modelData.summary || ""
                    color: Color.surfaceText
                    font.family: Tokens.fontFamily
                    font.pixelSize: Tokens.bodySmSize
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
