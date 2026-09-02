import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Modules.SettingsPanel.Controls

// Settings panel: top-level tabs in the sidebar, some split into subtabs
// via SubTabBar.qml. New top-level tabs go in the `tabs` model below.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property string screenName: screen ? screen.name : ""
  property string activeTab: "general"

  // Fuzzy-search sidebar state. jumpSubTab is read once (onChanged, not a
  // binding) so later manual SubTabBar clicks aren't fought by a stale hit.
  property string searchQuery: ""
  property string jumpSubTab: ""
  readonly property var searchResults: {
    if (root.searchQuery.trim() === "")
      return [];
    var hits = FuzzySort.go(root.searchQuery, searchIndex.entries, {
                               "keys": ["label", "keywords"],
                               "limit": 20,
                               "threshold": 0.3
                             });
    var out = [];
    for (var i = 0; i < hits.length; i++)
      out.push(hits[i].obj);
    return out;
  }

  function jumpToSearchHit(entry) {
    root.activeTab = entry.tab;
    if (entry.subTab)
      root.jumpSubTab = entry.subTab;
    root.searchQuery = "";
  }

  SettingsSearchIndex {
    id: searchIndex
  }

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
      "id": "controlCenter",
      "label": "Control Center"
    },
    {
      "id": "launcher",
      "label": "Launcher"
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
      "id": "connections",
      "label": "Connections"
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

  // Screen-specific target for callers (e.g. ControlCenterWindow's gear
  // icon) that already know their own screen and want Settings to open
  // there specifically, regardless of OS focus.
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

  // A plain "settings" alias, claimed only by the instance on the
  // currently-focused monitor, for a keybind that doesn't know/care which
  // screen it's on.
  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
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

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            Item {
              id: searchBox
              Layout.fillWidth: true
              Layout.preferredHeight: 28

              Chamfer {
                anchors.fill: parent
                chamferSize: Tokens.chamferIcon
                cutTopRight: true
                cutBottomLeft: true
                fillColor: Color.surfaceContainer
                strokeColor: searchInput.activeFocus ? Color.primary : Color.outline
                strokeWidth: Tokens.borderModule
              }

              TextInput {
                id: searchInput
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                color: Color.surfaceText
                font.family: Tokens.fontFamily
                font.pixelSize: Tokens.bodySmSize
                clip: true
                text: root.searchQuery
                onTextChanged: root.searchQuery = text

                Text {
                  visible: searchInput.text === "" && !searchInput.activeFocus
                  text: "Search settings…"
                  color: Color.labelText
                  font.family: Tokens.fontFamily
                  font.pixelSize: Tokens.bodySmSize
                  verticalAlignment: Text.AlignVCenter
                  anchors.fill: parent
                }
              }
            }

            Flickable {
              Layout.fillWidth: true
              Layout.fillHeight: true
              clip: true
              contentWidth: width
              contentHeight: root.searchQuery.trim() === "" ? sidebarCol.implicitHeight : resultsCol.implicitHeight

              ColumnLayout {
                id: sidebarCol
                width: parent.width
                spacing: 4
                visible: root.searchQuery.trim() === ""

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

              ColumnLayout {
                id: resultsCol
                width: parent.width
                spacing: 2
                visible: root.searchQuery.trim() !== ""

                Text {
                  text: root.searchResults.length === 0 ? "No matches" : root.searchResults.length + " match" + (root.searchResults.length === 1 ? "" : "es")
                  color: Color.labelText
                  font.family: Tokens.fontFamily
                  font.pixelSize: Tokens.labelXsSize
                  font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
                  Layout.bottomMargin: 10
                  Layout.topMargin: 2
                  Layout.leftMargin: 4
                }

                Repeater {
                  model: root.searchResults

                  delegate: Item {
                    id: resultItem
                    required property var modelData
                    Layout.fillWidth: true
                    height: 40

                    Rectangle {
                      anchors.fill: parent
                      color: resultHover.hovered ? Color.surfaceContainerHigh : "transparent"
                    }

                    ColumnLayout {
                      anchors.left: parent.left
                      anchors.leftMargin: 10
                      anchors.right: parent.right
                      anchors.rightMargin: 6
                      anchors.verticalCenter: parent.verticalCenter
                      spacing: 1

                      Text {
                        text: resultItem.modelData.label
                        color: Color.surfaceText
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.bodySmSize
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                      }
                      Text {
                        text: resultItem.modelData.description
                        color: Color.labelText
                        font.family: Tokens.fontFamily
                        font.pixelSize: Tokens.captionSize
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                      }
                    }

                    HoverHandler {
                      id: resultHover
                      cursorShape: Qt.PointingHandCursor
                    }
                    TapHandler {
                      onTapped: root.jumpToSearchHit(resultItem.modelData)
                    }
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
          // Defensive: clips tabs taller than the card (see notes.md).
          clip: true

          GeneralTab {
            anchors.fill: parent
            visible: root.activeTab === "general"
            initialSubTab: root.activeTab === "general" ? root.jumpSubTab : ""
          }

          BarTab {
            anchors.fill: parent
            visible: root.activeTab === "bar"
            screenName: root.screenName
            initialSubTab: root.activeTab === "bar" ? root.jumpSubTab : ""
          }

          AppearanceTab {
            anchors.fill: parent
            visible: root.activeTab === "appearance"
            initialSubTab: root.activeTab === "appearance" ? root.jumpSubTab : ""
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
            initialSubTab: root.activeTab === "display" ? root.jumpSubTab : ""
          }

          SystemMonitorTab {
            anchors.fill: parent
            visible: root.activeTab === "systemMonitor"
          }

          WallpaperTab {
            anchors.fill: parent
            visible: root.activeTab === "wallpaper"
          }

          ControlCenterTab {
            anchors.fill: parent
            visible: root.activeTab === "controlCenter"
          }

          LauncherTab {
            anchors.fill: parent
            visible: root.activeTab === "launcher"
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
            initialSubTab: root.activeTab === "lockScreen" ? root.jumpSubTab : ""
          }

          IdleTab {
            anchors.fill: parent
            visible: root.activeTab === "idle"
            initialSubTab: root.activeTab === "idle" ? root.jumpSubTab : ""
          }

          NotificationsTab {
            anchors.fill: parent
            visible: root.activeTab === "notifications"
            initialSubTab: root.activeTab === "notifications" ? root.jumpSubTab : ""
          }

          PeripheralsTab {
            anchors.fill: parent
            visible: root.activeTab === "peripherals"
          }

          ConnectionsTab {
            anchors.fill: parent
            visible: root.activeTab === "connections"
          }

          HooksTab {
            anchors.fill: parent
            visible: root.activeTab === "hooks"
            targetScreen: root.targetScreen
            initialSubTab: root.activeTab === "hooks" ? root.jumpSubTab : ""
          }

          PluginsTab {
            anchors.fill: parent
            visible: root.activeTab === "plugins"
            initialSubTab: root.activeTab === "plugins" ? root.jumpSubTab : ""
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
