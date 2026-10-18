import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Popups

// Clipboard history from cliphist.
ColumnLayout {
  id: root

  spacing: Tokens.spaceLg

  // Bound to the card's shown state; refreshes the list on open.
  property bool active: false
  onActiveChanged: if (root.active)
    root.refresh()

  // Asks PopupHost to close the card after copying an entry.
  signal requestClose

  readonly property bool cliphistAvailable: ClipboardService.available
  property var entries: []

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

  PopupHeader {
    title: "CLIPBOARD"
    action: "CLEAR ALL"
    onActionTapped: wipeProc.running = true
  }

  NText {
    visible: !root.cliphistAvailable
    text: "cliphist not found"
    color: Colors.labelText
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
      height: Tokens.rowHeight

      PopupRowBackground {
        hovered: rowHover.hovered
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Tokens.spaceMd
        anchors.rightMargin: Tokens.spaceMd

        NText {
          text: rowItem.modelData.isImage ? "[image]" : rowItem.modelData.preview
          color: Colors.surfaceText
          size: NText.Size.BodySm
          elide: Text.ElideRight
          Layout.fillWidth: true
        }

        Text {
          text: "×"
          color: Colors.labelText
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
