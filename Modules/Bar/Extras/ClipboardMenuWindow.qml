import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Modules.Bar.Extras

// Clipboard history popup. Backend is cliphist (same as noctalia-shell), not Omarchy's own capture.sh.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  // Anchor beside whichever edge the bar actually occupies instead of a
  // hardcoded screen corner — see the matching comment in
  // SoundMenuWindow.qml for the full reasoning.
  readonly property string _barPos: Settings.isLoaded ? Settings.getBarPositionForScreen(root.targetScreen ? root.targetScreen.name : "") : "top"
  readonly property bool _barLeft: root._barPos === "left"
  readonly property bool _barRight: root._barPos === "right"
  readonly property bool _barBottom: root._barPos === "bottom"
  readonly property bool _barTop: !root._barLeft && !root._barRight && !root._barBottom
  readonly property real _barOffset: Settings.data.bar.thickness + Settings.data.bar.floatMargin

  // Bar-icon trigger position, mapped into this popup's space; -1 = not set (IPC open). See SoundMenuWindow.qml.
  property point triggerPos: Qt.point(-1, -1)
  readonly property bool _hasTrigger: triggerPos.x >= 0
  readonly property real _triggerX: triggerPos.x + Settings.data.bar.floatMargin
  readonly property real _triggerY: triggerPos.y + Settings.data.bar.floatMargin

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
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
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

  Item {
    id: card
    // Cross-axis position (along the bar's own length): lines up with the
    // triggering icon when known, clamped on-screen; falls back to the old
    // fixed near-corner inset otherwise. Main-axis position (the gap
    // between the bar and the popup) always uses _barOffset, unchanged.
    readonly property real _crossFallback: 12
    readonly property real _crossPos: {
      if (root._barLeft || root._barRight)
        return root._hasTrigger ? Math.max(8, Math.min(root._triggerY, root.height - card.height - 8)) : _crossFallback;
      return root._hasTrigger ? Math.max(8, Math.min(root._triggerX, root.width - card.width - 8)) : root.width - card.width - _crossFallback;
    }

    x: root._barLeft ? root._barOffset : (root._barRight ? root.width - card.width - root._barOffset : card._crossPos)
    y: root._barBottom ? root.height - card.height - root._barOffset : (root._barLeft || root._barRight ? card._crossPos : root._barOffset)
    width: 340
    height: Math.min(480, column.implicitHeight + 24)

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      // Flush against the bar, so cut only the two corners on the far
      // side from it -- the near side reads as growing out of the bar
      // instead of floating as a fully separate chamfered card.
      cutTopLeft: root._barBottom || root._barRight
      cutTopRight: root._barBottom || root._barLeft
      cutBottomLeft: root._barTop || root._barRight
      cutBottomRight: root._barTop || root._barLeft
      omitStrokeSide: root._barBottom ? "bottom" : (root._barLeft ? "left" : (root._barRight ? "right" : "top"))
      fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
      strokeColor: Color.outline
      strokeWidth: Tokens.borderPanel
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      id: column
      anchors.fill: parent
      anchors.margins: 14
      spacing: 10

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "CLIPBOARD"
          color: Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.weight: Font.DemiBold
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          Layout.fillWidth: true
        }

        Text {
          text: "CLEAR ALL"
          color: Color.error
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
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
        color: Color.labelText
        font.family: Tokens.fontFamily
        font.pixelSize: Tokens.bodySmSize
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

            Text {
              text: rowItem.modelData.isImage ? "[image]" : rowItem.modelData.preview
              color: Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySmSize
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
  }
}
