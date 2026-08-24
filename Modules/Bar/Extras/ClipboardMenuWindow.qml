import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

// Clipboard history popup. Backend is cliphist (already installed, already
// what noctalia-shell uses — see Services/Keyboard/ClipboardService.qml for
// the proven watch/list/decode/delete command shapes this mirrors) rather
// than Omarchy's own capture.sh, which does its own image-hashing/dedup
// layer cliphist already handles.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  property bool cliphistAvailable: false
  property var entries: []

  Process {
    id: checkProc
    command: ["sh", "-c", "command -v cliphist"]
    onExited: function (exitCode) {
      root.cliphistAvailable = exitCode === 0;
      if (root.cliphistAvailable)
        startWatchers();
    }
  }

  Process {
    id: watchText
    command: ["wl-paste", "--type", "text", "--watch", "cliphist", "store"]
    onExited: watchTextRestart.restart()
  }
  Timer {
    id: watchTextRestart
    interval: 1000
    onTriggered: if (root.cliphistAvailable)
      watchText.running = true
  }

  Process {
    id: watchImage
    command: ["wl-paste", "--type", "image", "--watch", "cliphist", "store"]
    onExited: watchImageRestart.restart()
  }
  Timer {
    id: watchImageRestart
    interval: 1000
    onTriggered: if (root.cliphistAvailable)
      watchImage.running = true
  }

  function startWatchers() {
    watchText.running = true;
    watchImage.running = true;
  }

  Component.onCompleted: checkProc.running = true

  function refresh() {
    if (!cliphistAvailable || listProc.running)
      return;
    listProc.running = true;
  }

  Process {
    id: listProc
    command: ["cliphist", "list", "-preview-width", "60"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = text.split("\n").filter(function (l) {
          return l.length > 0;
        });
        root.entries = lines.map(function (line) {
          var tab = line.indexOf("\t");
          var id = tab > -1 ? line.slice(0, tab) : line;
          var preview = tab > -1 ? line.slice(tab + 1) : "";
          var isImage = preview.toLowerCase().indexOf("binary data") !== -1;
          return {
            "id": id,
            "preview": preview,
            "isImage": isImage
          };
        });
      }
    }
  }

  Process {
    id: copyProc
  }

  function copyEntry(id) {
    copyProc.command = ["sh", "-c", "cliphist decode " + id + " | wl-copy"];
    copyProc.running = true;
    root.visible = false;
  }

  Process {
    id: deleteProc
    onExited: root.refresh()
  }

  function deleteEntry(id) {
    deleteProc.command = ["sh", "-c", "echo " + id + " | cliphist delete"];
    deleteProc.running = true;
  }

  Process {
    id: wipeProc
    command: ["cliphist", "wipe"]
    onExited: root.refresh()
  }

  function toggle() {
    visible = !visible;
    if (visible)
      refresh();
  }

  IpcHandler {
    enabled: root.targetScreen === Quickshell.screens[0]
    target: "clipboard"
    function toggle() {
      root.toggle();
    }
    function show() {
      if (!root.visible)
        root.toggle();
    }
    function hide() {
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
  WlrLayershell.namespace: "crux-clipboard-menu"
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
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: 40
    anchors.rightMargin: 12
    width: 340
    height: Math.min(480, column.implicitHeight + 24)
    radius: Style.radiusXXS
    color: Color.mSurface
    border.color: Color.mOutline
    border.width: 1

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      id: column
      anchors.fill: parent
      anchors.margins: 12
      spacing: 8

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "Clipboard"
          color: Color.mOnSurface
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: 14
          font.bold: true
          Layout.fillWidth: true
        }

        Text {
          text: "clear all"
          color: Color.mError
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: 11
          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: wipeProc.running = true
          }
        }
      }

      Text {
        visible: !root.cliphistAvailable
        text: "cliphist not found"
        color: Color.mOnSurfaceVariant
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: 12
      }

      ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(400, contentHeight)
        clip: true
        visible: root.cliphistAvailable
        model: root.entries
        spacing: 2

        delegate: Item {
          id: rowItem
          required property var modelData
          width: ListView.view.width
          height: 32

          RowLayout {
            anchors.fill: parent

            Text {
              text: rowItem.modelData.isImage ? "[image]" : rowItem.modelData.preview
              color: Color.mOnSurface
              font.family: Settings.data.ui.fontFamily
              font.pixelSize: 12
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Text {
              text: "×"
              color: Color.mOnSurfaceVariant
              font.pixelSize: 14
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.deleteEntry(rowItem.modelData.id)
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            z: -1
            cursorShape: Qt.PointingHandCursor
            onClicked: root.copyEntry(rowItem.modelData.id)
          }
        }
      }
    }
  }
}
