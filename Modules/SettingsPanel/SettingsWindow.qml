import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls

// Settings panel: General, Bar, Appearance, Audio, System Monitor, and
// Wallpaper, each a top-level tab in the sidebar — several (Bar,
// Appearance, General) further split into subtabs via SubTabBar.qml, the
// same two-level Tab -> SubTab navigation noctalia's own settings panel
// uses. New top-level tabs go in the `tabs` model below; a tab with only
// one logical page just skips SubTabBar entirely (see AudioTab.qml,
// SystemMonitorTab.qml, WallpaperTab.qml) rather than showing a pointless
// single-pill bar.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property string screenName: screen ? screen.name : ""
  property string activeTab: "general"

  readonly property var tabs: [
    {
      "id": "general",
      "label": "General"
    },
    {
      "id": "bar",
      "label": "Bar"
    },
    {
      "id": "appearance",
      "label": "Appearance"
    },
    {
      "id": "audio",
      "label": "Audio"
    },
    {
      "id": "hue",
      "label": "Hue"
    },
    {
      "id": "display",
      "label": "Display"
    },
    {
      "id": "systemMonitor",
      "label": "System Monitor"
    },
    {
      "id": "wallpaper",
      "label": "Wallpaper"
    },
    {
      "id": "desktopWidgets",
      "label": "Desktop Widgets"
    },
    {
      "id": "osd",
      "label": "OSD"
    },
    {
      "id": "sessionMenu",
      "label": "Session Menu"
    },
    {
      "id": "lockScreen",
      "label": "Lock Screen"
    },
    {
      "id": "idle",
      "label": "Idle"
    },
    {
      "id": "notifications",
      "label": "Notifications"
    },
    {
      "id": "peripherals",
      "label": "Peripherals"
    },
    {
      "id": "hooks",
      "label": "Hooks"
    },
    {
      "id": "plugins",
      "label": "Plugins"
    },
    {
      "id": "about",
      "label": "About"
    }
  ]

  function toggle() {
    visible = !visible;
  }

  // Screen-specific target so a caller that already knows which screen it's
  // on (Control Center's own gear icon, bin/crux-focused-ipc for a keybind)
  // can reach *this* screen's instance specifically instead of always
  // hitting whichever screen owns the generic "settings" name below —
  // confirmed real bug: Control Center's gear icon always opened Settings
  // on screens[0], not the screen Control Center itself was open on. No
  // `enabled` gate needed since the name itself is already unique per
  // screen.
  IpcHandler {
    target: "settings_" + (root.targetScreen ? root.targetScreen.name : "0")
    function toggle() {
      root.toggle();
    }
    function open() {
      root.visible = true;
    }
    function openTab(tab: string) {
      root.activeTab = tab;
      root.visible = true;
    }
    function close() {
      root.visible = false;
    }
  }

  // A plain "settings" alias on just one instance, purely so a script or
  // keybind that doesn't know/care which screen it's on still has something
  // simple to call.
  IpcHandler {
    enabled: root.targetScreen === Quickshell.screens[0]
    target: "settings"
    function toggle() {
      root.toggle();
    }
    function open() {
      root.visible = true;
    }
    function openTab(tab: string) {
      root.activeTab = tab;
      root.visible = true;
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
  WlrLayershell.namespace: "crux-settings"
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
    anchors.centerIn: parent
    width: 860
    height: 620

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

    RowLayout {
      anchors.fill: parent
      spacing: 0

      // ---------------- Sidebar ----------------
      ColumnLayout {
        Layout.preferredWidth: 150
        Layout.minimumWidth: 150
        Layout.maximumWidth: 150
        Layout.fillHeight: true
        spacing: 2

        Item {
          Layout.fillWidth: true
          Layout.fillHeight: true

          Rectangle {
            anchors.fill: parent
            color: Color.surfaceContainerLow
            border.color: Color.outline
            border.width: Tokens.borderPanel
          }

          Flickable {
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            contentWidth: width
            contentHeight: sidebarCol.implicitHeight

            ColumnLayout {
            id: sidebarCol
            width: parent.width
            spacing: 4

            Text {
              text: "SETTINGS"
              color: Color.labelText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
              font.weight: Font.DemiBold
              font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
              Layout.bottomMargin: 10
              Layout.topMargin: 2
              Layout.leftMargin: 4
            }

            Repeater {
              model: root.tabs

              delegate: Item {
                id: sidebarItem
                required property var modelData
                readonly property bool active: root.activeTab === modelData.id
                Layout.fillWidth: true
                height: 32

                Rectangle {
                  anchors.fill: parent
                  color: sidebarItem.active ? Color.primaryContainer : (tabHover.hovered ? Color.surfaceContainerHigh : "transparent")
                }
                Rectangle {
                  visible: sidebarItem.active
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  width: Tokens.borderMarker
                  color: Color.primary
                }

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: 10
                  anchors.right: parent.right
                  anchors.rightMargin: 6
                  anchors.verticalCenter: parent.verticalCenter
                  text: sidebarItem.modelData.label
                  color: sidebarItem.active ? Color.primaryContainerText : Color.surfaceText
                  font.family: Tokens.fontFamily
                  font.pixelSize: Tokens.bodySmSize
                  font.weight: sidebarItem.active ? Font.DemiBold : Font.Normal
                  elide: Text.ElideRight
                }

                HoverHandler {
                  id: tabHover
                  cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                  onTapped: root.activeTab = sidebarItem.modelData.id
                }
              }
            }
            }
          }
        }
      }

      // ---------------- Content ----------------
      ColumnLayout {
        id: contentPane
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: 16
        spacing: 12

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 8

          RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
              width: 3
              height: 16
              color: Color.primary
            }

            Text {
              text: {
                for (var i = 0; i < root.tabs.length; i++)
                  if (root.tabs[i].id === root.activeTab)
                    return root.tabs[i].label;
                return "";
              }
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodyLgSize
              font.weight: Font.DemiBold
              Layout.fillWidth: true
            }

            // Chamfered close tile with a Canvas-drawn X — no font-glyph
            // dependency (same reasoning as every bar icon).
            Item {
              id: closeBtn
              width: 26
              height: 26

              Chamfer {
                anchors.fill: parent
                chamferSize: Tokens.chamferIcon
                cutTopRight: true
                cutBottomLeft: true
                fillColor: closeHover.hovered ? Color.alpha(Color.error, 0.16) : "transparent"
                strokeColor: Color.alpha(Color.error, closeHover.hovered ? 0.7 : Tokens.destructiveBorderAlpha)
                strokeWidth: Tokens.borderModule
              }

              Canvas {
                id: closeGlyph
                anchors.centerIn: parent
                width: 10
                height: 10
                readonly property color strokeColor: closeHover.hovered ? Color.error : Color.surfaceTextMuted
                onStrokeColorChanged: requestPaint()
                onPaint: {
                  var ctx = getContext("2d");
                  ctx.reset();
                  ctx.strokeStyle = strokeColor;
                  ctx.lineWidth = 1.6;
                  ctx.lineCap = "round";
                  ctx.beginPath();
                  ctx.moveTo(0, 0);
                  ctx.lineTo(width, height);
                  ctx.moveTo(width, 0);
                  ctx.lineTo(0, height);
                  ctx.stroke();
                }
              }

              HoverHandler {
                id: closeHover
                cursorShape: Qt.PointingHandCursor
              }
              TapHandler {
                onTapped: root.visible = false
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Tokens.borderDivider
            color: Color.surfaceContainerHigh
          }
        }

        Item {
          id: tabContentArea
          Layout.fillWidth: true
          Layout.fillHeight: true
          // Defensive — a tab whose content is taller than the card was
          // rendering straight past the panel's edge instead of scrolling
          // (most tabs are a plain ColumnLayout, not a Flickable). This
          // stops the visual spill; the real fix is giving each tab actual
          // scroll (see crux skill's notes.md).
          clip: true

          GeneralTab {
            anchors.fill: parent
            visible: root.activeTab === "general"
          }

          BarTab {
            anchors.fill: parent
            visible: root.activeTab === "bar"
            screenName: root.screenName
          }

          AppearanceTab {
            anchors.fill: parent
            visible: root.activeTab === "appearance"
          }

          AudioTab {
            anchors.fill: parent
            visible: root.activeTab === "audio"
          }

          HueTab {
            anchors.fill: parent
            visible: root.activeTab === "hue"
          }

          DisplayTab {
            anchors.fill: parent
            visible: root.activeTab === "display"
          }

          SystemMonitorTab {
            anchors.fill: parent
            visible: root.activeTab === "systemMonitor"
          }

          WallpaperTab {
            anchors.fill: parent
            visible: root.activeTab === "wallpaper"
          }

          DesktopWidgetsTab {
            anchors.fill: parent
            visible: root.activeTab === "desktopWidgets"
          }

          OsdTab {
            anchors.fill: parent
            visible: root.activeTab === "osd"
          }

          SessionMenuTab {
            anchors.fill: parent
            visible: root.activeTab === "sessionMenu"
          }

          LockScreenTab {
            anchors.fill: parent
            visible: root.activeTab === "lockScreen"
          }

          IdleTab {
            anchors.fill: parent
            visible: root.activeTab === "idle"
          }

          NotificationsTab {
            anchors.fill: parent
            visible: root.activeTab === "notifications"
          }

          PeripheralsTab {
            anchors.fill: parent
            visible: root.activeTab === "peripherals"
          }

          HooksTab {
            anchors.fill: parent
            visible: root.activeTab === "hooks"
            targetScreen: root.targetScreen
          }

          PluginsTab {
            anchors.fill: parent
            visible: root.activeTab === "plugins"
          }

          AboutTab {
            anchors.fill: parent
            visible: root.activeTab === "about"
          }
        }
      }
    }
  }
}
