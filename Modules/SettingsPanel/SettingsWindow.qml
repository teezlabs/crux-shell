import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
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
      "id": "systemMonitor",
      "label": "System Monitor"
    },
    {
      "id": "wallpaper",
      "label": "Wallpaper"
    }
  ]

  function toggle() {
    visible = !visible;
  }

  IpcHandler {
    enabled: root.targetScreen === Quickshell.screens[0]
    target: "settings"
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

  // Soft drop shadow behind the card, same treatment as the bar itself
  // (shell.qml) — depth against whatever's behind the popup.
  MultiEffect {
    anchors.fill: card
    source: card
    shadowEnabled: true
    shadowColor: Qt.rgba(0, 0, 0, 0.55)
    shadowBlur: 0.7
    shadowVerticalOffset: 3
    shadowHorizontalOffset: 0
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: 860
    height: 620
    radius: Style.radiusS
    color: Color.mSurface
    border.color: Color.mOutline
    border.width: 1

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

        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          color: Color.mSurfaceVariant

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            Text {
              text: "Settings"
              color: Color.mOnSurface
              font.family: Settings.data.ui.fontFamily
              font.pixelSize: Style.fontSizeL
              font.bold: true
              Layout.bottomMargin: 8
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
                  id: activeBar
                  visible: sidebarItem.active
                  width: 3
                  radius: 1.5
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  anchors.margins: 3
                  color: Color.mPrimary
                }

                Rectangle {
                  anchors.fill: parent
                  anchors.leftMargin: sidebarItem.active ? 6 : 0
                  radius: Style.radiusXS
                  color: sidebarItem.active ? Color.alpha(Color.mPrimary, 0.22) : (tabMouse.containsMouse ? Color.alpha(Color.mPrimary, 0.12) : "transparent")
                  border.color: Color.alpha(Color.mPrimary, 0.55)
                  border.width: !sidebarItem.active && tabMouse.containsMouse ? 1 : 0
                  Behavior on color {
                    ColorAnimation {
                      duration: Style.animationFast
                    }
                  }

                  Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: sidebarItem.modelData.label
                    color: sidebarItem.active ? Color.mPrimary : Color.mOnSurface
                    font.family: Settings.data.ui.fontFamily
                    font.pixelSize: Style.fontSizeM
                    font.bold: sidebarItem.active
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  id: tabMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.activeTab = sidebarItem.modelData.id
                }
              }
            }

            Item {
              Layout.fillHeight: true
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

        // Per-tab header — noctalia's own settings content header
        // (SettingsContent.qml): bold accent-colored title + a real close
        // button, instead of relying only on click-outside/Escape to close.
        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Text {
            text: {
              for (var i = 0; i < root.tabs.length; i++)
                if (root.tabs[i].id === root.activeTab)
                  return root.tabs[i].label;
              return "";
            }
            color: Color.mPrimary
            font.family: Settings.data.ui.fontFamily
            font.pixelSize: Style.fontSizeL
            font.bold: true
            Layout.fillWidth: true
          }

          Rectangle {
            id: closeBtn
            width: 26
            height: 26
            radius: Style.radiusXS
            color: closeHover.hovered ? Color.alpha(Color.mError, 0.18) : "transparent"
            border.color: Color.alpha(Color.mError, 0.55)
            border.width: closeHover.hovered ? 1 : 0
            Behavior on color {
              ColorAnimation {
                duration: Style.animationFast
              }
            }

            Text {
              anchors.centerIn: parent
              text: "×"
              color: closeHover.hovered ? Color.mError : Color.mOnSurfaceVariant
              font.pixelSize: Style.fontSizeL
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

        Item {
          id: tabContentArea
          Layout.fillWidth: true
          Layout.fillHeight: true

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

          SystemMonitorTab {
            anchors.fill: parent
            visible: root.activeTab === "systemMonitor"
          }

          WallpaperTab {
            anchors.fill: parent
            visible: root.activeTab === "wallpaper"
          }
        }
      }
    }
  }
}
