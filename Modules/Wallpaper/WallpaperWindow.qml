import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Modules.Wallpaper

// Wallpaper picker popup: a grid of thumbnails backed by skwd-daemon's own
// wallpaper index (SkwdClient.qml — a fresh client written against the
// daemon's live JSON-RPC socket protocol, not ported from noctalia). Picking
// one calls wall.apply, which skwd-daemon itself applies via its configured
// externalWallpaperCommand (aurora-wallpaper-apply) — that script sets
// Settings.data.wallpaper.path (crux's own Background.qml reads it) and
// re-derives the live theme via matugen. This window doesn't touch either
// of those directly; it only asks skwd-daemon to apply.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  property var wallpapers: []

  function toggle() {
    visible = !visible;
    if (visible)
      refresh();
  }

  function refresh() {
    SkwdClient.listWallpapers(function (list, error) {
      if (!error)
        root.wallpapers = list;
    });
  }

  Connections {
    target: SkwdClient
    function onListChanged() {
      if (root.visible)
        root.refresh();
    }
  }

  IpcHandler {
    enabled: root.targetScreen && root.targetScreen.name === "DP-2"
    target: "wallpaperPicker"
    function toggle() {
      root.toggle();
    }
    function open() {
      root.visible = true;
      root.refresh();
    }
    function close() {
      root.visible = false;
    }
  }

  visible: false
  color: "transparent"

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-wallpaper-picker"
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
    width: Math.min(parent.width - 80, 980)
    height: Math.min(parent.height - 80, 640)
    radius: Style.radiusS
    color: Color.mSurface
    border.color: Color.mOutline
    border.width: 1

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 12

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "Wallpaper"
          color: Color.mOnSurface
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: Style.fontSizeL
          font.bold: true
        }

        Item {
          Layout.fillWidth: true
        }

        Text {
          text: SkwdClient.connected ? root.wallpapers.length + " wallpapers" : "skwd-daemon not connected"
          color: SkwdClient.connected ? Color.mOnSurfaceVariant : Color.mError
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: Style.fontSizeS
        }
      }

      GridView {
        id: grid
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        cellWidth: 176
        cellHeight: 110
        model: root.wallpapers

        delegate: Item {
          id: cell
          required property var modelData
          width: grid.cellWidth
          height: grid.cellHeight

          readonly property string fullPath: Settings.data.wallpaper.directory + "/" + (modelData.name || "")
          readonly property bool isCurrent: fullPath === Settings.data.wallpaper.path

          Rectangle {
            anchors.fill: parent
            anchors.margins: 6
            radius: Style.radiusXS
            color: Color.mSurfaceVariant
            border.color: cell.isCurrent ? Color.mPrimary : (hoverHandler.hovered ? Color.mOutline : "transparent")
            border.width: cell.isCurrent ? 2 : 1
            clip: true

            Image {
              anchors.fill: parent
              anchors.margins: cell.isCurrent ? 1 : 0
              source: modelData.thumb_sm ? "file://" + modelData.thumb_sm : ""
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: false
            }

            Text {
              anchors.left: parent.left
              anchors.bottom: parent.bottom
              anchors.margins: 4
              visible: hoverHandler.hovered
              text: modelData.name || ""
              color: Color.mOnSurface
              font.family: Settings.data.ui.fontFamily
              font.pixelSize: Style.fontSizeXS
              elide: Text.ElideRight
              width: parent.width - 8

              Rectangle {
                z: -1
                anchors.fill: parent
                anchors.margins: -3
                color: Color.alpha(Color.mSurface, 0.75)
                radius: Style.radiusXXS
              }
            }
          }

          HoverHandler {
            id: hoverHandler
            cursorShape: Qt.PointingHandCursor
          }

          TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: SkwdClient.applyStatic(cell.fullPath)
          }
        }
      }
    }
  }
}
