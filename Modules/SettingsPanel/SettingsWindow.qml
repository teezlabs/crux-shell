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

  // Faint outer accent glow around the whole card — separate from the drop
  // shadow above (which is pure black depth), this one is primary-tinted
  // and reads as "this thing is powered on" rather than just "elevated".
  MultiEffect {
    anchors.fill: card
    source: card
    shadowEnabled: true
    shadowColor: Color.mPrimary
    shadowBlur: 0.4
    shadowOpacity: 0.25
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: 860
    height: 620
    radius: Style.radiusS
    border.color: Color.alpha(Color.mPrimary, 0.4)
    border.width: 1

    gradient: Gradient {
      GradientStop {
        position: 0
        color: Qt.lighter(Color.mSurface, 1.06)
      }
      GradientStop {
        position: 1
        color: Color.mSurface
      }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    // HUD-style corner brackets — a restrained sci-fi framing cue, inset
    // just past the border rather than drawn on top of it.
    Repeater {
      model: [{
        "corner": "tl"
      }, {
        "corner": "tr"
      }, {
        "corner": "bl"
      }, {
        "corner": "br"
      }]

      delegate: Item {
        id: bracket
        required property var modelData
        readonly property bool isTop: modelData.corner === "tl" || modelData.corner === "tr"
        readonly property bool isLeft: modelData.corner === "tl" || modelData.corner === "bl"
        readonly property int inset: 6
        readonly property int armLen: 16

        anchors.top: isTop ? card.top : undefined
        anchors.bottom: !isTop ? card.bottom : undefined
        anchors.left: isLeft ? card.left : undefined
        anchors.right: !isLeft ? card.right : undefined
        anchors.topMargin: isTop ? inset : 0
        anchors.bottomMargin: !isTop ? inset : 0
        anchors.leftMargin: isLeft ? inset : 0
        anchors.rightMargin: !isLeft ? inset : 0
        width: armLen
        height: armLen

        Rectangle {
          width: bracket.armLen
          height: 2
          color: Color.alpha(Color.mPrimary, 0.6)
          anchors.top: bracket.isTop ? parent.top : undefined
          anchors.bottom: !bracket.isTop ? parent.bottom : undefined
          anchors.left: bracket.isLeft ? parent.left : undefined
          anchors.right: !bracket.isLeft ? parent.right : undefined
        }
        Rectangle {
          width: 2
          height: bracket.armLen
          color: Color.alpha(Color.mPrimary, 0.6)
          anchors.top: bracket.isTop ? parent.top : undefined
          anchors.bottom: !bracket.isTop ? parent.bottom : undefined
          anchors.left: bracket.isLeft ? parent.left : undefined
          anchors.right: !bracket.isLeft ? parent.right : undefined
        }
      }
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
          radius: Style.radiusS
          border.color: Color.alpha(Color.mPrimary, 0.15)
          border.width: 1

          gradient: Gradient {
            GradientStop {
              position: 0
              color: Qt.lighter(Color.mSurfaceVariant, 1.1)
            }
            GradientStop {
              position: 1
              color: Color.mSurfaceVariant
            }
          }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            RowLayout {
              spacing: 8
              Layout.bottomMargin: 10
              Layout.topMargin: 2
              Layout.leftMargin: 4

              Rectangle {
                width: 6
                height: 6
                radius: 3
                color: Color.mPrimary
              }

              Text {
                text: "SETTINGS"
                color: Color.mOnSurface
                font.family: Settings.data.ui.fontFamily
                font.pixelSize: Style.fontSizeM
                font.bold: true
                font.letterSpacing: 2
              }
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

                MultiEffect {
                  anchors.fill: activeBar
                  source: activeBar
                  visible: sidebarItem.active
                  shadowEnabled: true
                  shadowColor: Color.mPrimary
                  shadowBlur: 0.5
                  shadowOpacity: 0.8
                }

                Rectangle {
                  anchors.fill: parent
                  anchors.leftMargin: sidebarItem.active ? 6 : 0
                  radius: Style.radiusXS
                  color: sidebarItem.active ? Color.alpha(Color.mPrimary, 0.18) : (tabMouse.containsMouse ? Color.alpha(Color.mPrimary, 0.12) : "transparent")
                  border.color: Color.alpha(Color.mPrimary, sidebarItem.active ? 0.4 : 0.55)
                  border.width: sidebarItem.active || tabMouse.containsMouse ? 1 : 0
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
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 8

          RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
              width: 4
              height: 18
              radius: 2
              color: Color.mPrimary
            }

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
              font.letterSpacing: 0.5
              Layout.fillWidth: true
            }

            // Circular close button with a Canvas-drawn X — no font-glyph
            // dependency (same reasoning as every bar icon), with a glow
            // on hover instead of a plain border swap.
            Rectangle {
              id: closeBtn
              width: 26
              height: 26
              radius: 13
              color: closeHover.hovered ? Color.alpha(Color.mError, 0.18) : "transparent"
              border.color: Color.alpha(Color.mError, closeHover.hovered ? 0.7 : 0.35)
              border.width: 1
              Behavior on color {
                ColorAnimation {
                  duration: Style.animationFast
                }
              }

              MultiEffect {
                anchors.fill: closeGlyph
                source: closeGlyph
                visible: closeHover.hovered
                shadowEnabled: true
                shadowColor: Color.mError
                shadowBlur: 0.5
                shadowOpacity: 0.7
              }

              Canvas {
                id: closeGlyph
                anchors.centerIn: parent
                width: 10
                height: 10
                readonly property color strokeColor: closeHover.hovered ? Color.mError : Color.mOnSurfaceVariant
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
            Layout.preferredHeight: 1
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop {
                position: 0
                color: Color.alpha(Color.mPrimary, 0.4)
              }
              GradientStop {
                position: 1
                color: "transparent"
              }
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
