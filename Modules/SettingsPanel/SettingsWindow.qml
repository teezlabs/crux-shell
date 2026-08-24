import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

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

              delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                height: 32
                radius: Style.radiusXS
                color: root.activeTab === modelData.id ? Color.mPrimary : (tabMouse.containsMouse ? Color.mOutline : "transparent")

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: 10
                  anchors.right: parent.right
                  anchors.rightMargin: 6
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.label
                  color: root.activeTab === modelData.id ? Color.mOnPrimary : Color.mOnSurface
                  font.family: Settings.data.ui.fontFamily
                  font.pixelSize: Style.fontSizeM
                  elide: Text.ElideRight
                }

                MouseArea {
                  id: tabMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.activeTab = modelData.id
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
      Item {
        id: contentPane
        Layout.fillWidth: true
        Layout.fillHeight: true

        GeneralTab {
          anchors.fill: parent
          anchors.margins: 16
          visible: root.activeTab === "general"
        }

        BarTab {
          anchors.fill: parent
          anchors.margins: 16
          visible: root.activeTab === "bar"
          screenName: root.screenName
        }

        AppearanceTab {
          anchors.fill: parent
          anchors.margins: 16
          visible: root.activeTab === "appearance"
        }

        AudioTab {
          anchors.fill: parent
          anchors.margins: 16
          visible: root.activeTab === "audio"
        }

        SystemMonitorTab {
          anchors.fill: parent
          anchors.margins: 16
          visible: root.activeTab === "systemMonitor"
        }

        WallpaperTab {
          anchors.fill: parent
          anchors.margins: 16
          visible: root.activeTab === "wallpaper"
        }
      }
    }
  }
}
