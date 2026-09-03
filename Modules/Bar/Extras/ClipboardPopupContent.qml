import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Widgets

// Clipboard history popup content. Backend is cliphist (same as
// noctalia-shell), not Omarchy's own capture.sh. Hosted inside a
// SlideCard by PopupHost.qml — no window/positioning of its own.
ColumnLayout {
  id: root

  spacing: 10

  // Bound to the owning SlideCard's `open` from PopupHost — refreshes the
  // list on open, same as the old toggle()-triggered refresh().
  property bool active: false
  onActiveChanged: if (root.active)
    root.refresh()

  // Emitted after copying an entry, so PopupHost closes the card — this
  // content has no window of its own to set visible on directly anymore.
  signal requestClose

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
        var limit = Settings.isLoaded ? Settings.data.clipboard.historyLimit : 50;
        root.entries = lines.slice(0, limit).map(function (line) {
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
    root.requestClose();
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

  RowLayout {
    Layout.fillWidth: true

    NText {
      tracking: true
      text: "CLIPBOARD"
      color: Color.labelText
      size: NText.Size.LabelXs
      font.weight: Font.DemiBold
      Layout.fillWidth: true
    }

    NText {
      tracking: true
      text: "CLEAR ALL"
      color: Color.error
      size: NText.Size.LabelXs
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: wipeProc.running = true
      }
    }
  }

  NText {
    visible: !root.cliphistAvailable
    text: "cliphist not found"
    color: Color.labelText
    size: NText.Size.BodySm
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

      Rectangle {
        anchors.fill: parent
        color: rowHover.hovered ? Color.surfaceContainerHigh : "transparent"
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        NText {
          text: rowItem.modelData.isImage ? "[image]" : rowItem.modelData.preview
          color: Color.surfaceText
          size: NText.Size.BodySm
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Text {
          text: "×"
          color: Color.labelText
          font.pixelSize: Tokens.bodyLgSize
          MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: root.deleteEntry(rowItem.modelData.id)
          }
        }
      }

      HoverHandler {
        id: rowHover
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
