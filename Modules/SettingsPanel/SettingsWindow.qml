import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Modules.Bar.Extras

// Settings panel: bar layout, per-section widget management (add/remove —
// complements the live drag-and-drop reordering on the bar itself), and
// appearance (the Color/Style tokens every widget now reads from). A
// proper sized window rather than a small popup, matching how "verbose"
// noctalia's own settings panel is.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  readonly property string screenName: screen ? screen.name : ""
  property string activeTab: "bar"

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
    width: 760
    height: 560
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
        Layout.preferredWidth: 140
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
              model: [
                {
                  "id": "bar",
                  "label": "Bar"
                },
                {
                  "id": "widgets",
                  "label": "Widgets"
                },
                {
                  "id": "appearance",
                  "label": "Appearance"
                }
              ]

              delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                height: 32
                radius: Style.radiusXS
                color: root.activeTab === modelData.id ? Color.mPrimary : (tabMouse.containsMouse ? Color.mOutline : "transparent")

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: 10
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.label
                  color: root.activeTab === modelData.id ? Color.mOnPrimary : Color.mOnSurface
                  font.family: Settings.data.ui.fontFamily
                  font.pixelSize: Style.fontSizeM
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
        Layout.fillWidth: true
        Layout.fillHeight: true

        BarTab {
          anchors.fill: parent
          anchors.margins: 16
          visible: root.activeTab === "bar"
          screenName: root.screenName
        }

        WidgetsTab {
          anchors.fill: parent
          anchors.margins: 16
          visible: root.activeTab === "widgets"
          screenName: root.screenName
        }

        AppearanceTab {
          anchors.fill: parent
          anchors.margins: 16
          visible: root.activeTab === "appearance"
        }
      }
    }
  }
}
