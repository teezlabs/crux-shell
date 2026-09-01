import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.Commons
import qs.Modules.Bar.Extras

// App launcher popup. Uses Quickshell's DesktopEntries singleton rather than scanning .desktop files by hand.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  property string query: ""
  property int selectedIndex: 0

  readonly property var allApps: {
    var apps = typeof DesktopEntries !== "undefined" && DesktopEntries.applications ? DesktopEntries.applications.values : [];
    return apps.filter(function (a) {
      return a && !a.noDisplay && !a.hidden;
    });
  }

  readonly property string _execPrefix: Settings.isLoaded ? Settings.data.launcher.execPrefix : ""
  readonly property bool execMode: root._execPrefix !== "" && query.indexOf(root._execPrefix) === 0
  readonly property string execCommand: root.execMode ? query.slice(root._execPrefix.length) : ""
  readonly property int _resultLimit: Settings.isLoaded ? Settings.data.launcher.resultLimit : 30

  readonly property var results: {
    if (root.execMode)
      return [];
    var q = query.trim().toLowerCase();
    var list = allApps;
    if (q !== "") {
      if (Settings.isLoaded && Settings.data.launcher.fuzzyMatch) {
        var hits = FuzzySort.go(query, allApps, {
                                   "keys": ["name", "genericName", "comment"],
                                   "limit": root._resultLimit
                                 });
        list = [];
        for (var h = 0; h < hits.length; h++)
          list.push(hits[h].obj);
        return list;
      }
      list = allApps.filter(function (a) {
        var name = (a.name || "").toLowerCase();
        var generic = (a.genericName || "").toLowerCase();
        var comment = (a.comment || "").toLowerCase();
        return name.indexOf(q) !== -1 || generic.indexOf(q) !== -1 || comment.indexOf(q) !== -1;
      });
      list.sort(function (a, b) {
        var an = (a.name || "").toLowerCase();
        var bn = (b.name || "").toLowerCase();
        var aStarts = an.indexOf(q) === 0;
        var bStarts = bn.indexOf(q) === 0;
        if (aStarts !== bStarts)
          return aStarts ? -1 : 1;
        return an.localeCompare(bn);
      });
    } else {
      list = list.slice().sort(function (a, b) {
        return (a.name || "").toLowerCase().localeCompare((b.name || "").toLowerCase());
      });
    }
    return list.slice(0, root._resultLimit);
  }

  function runExecCommand() {
    if (root.execCommand.trim() === "")
      return;
    Quickshell.execDetached(["sh", "-c", root.execCommand]);
    root.visible = false;
    root.query = "";
  }

  onQueryChanged: selectedIndex = 0
  onResultsChanged: if (selectedIndex >= results.length)
    selectedIndex = Math.max(0, results.length - 1)

  function launch(app) {
    if (!app)
      return;
    root.visible = false;
    query = "";
    Qt.callLater(function () {
      if (app.execute) {
        app.execute();
      } else if (app.command && app.command.length > 0) {
        Quickshell.execDetached(app.command);
      }
    });
  }

  function toggle() {
    visible = !visible;
    if (visible) {
      query = "";
      selectedIndex = 0;
      Qt.callLater(function () {
        searchInput.forceActiveFocus();
      });
    }
  }

  // Only the instance on the currently-focused monitor claims this target,
  // so SUPER+A always opens on the right screen with no external routing.
  IpcHandler {
    enabled: root.targetScreen && Hyprland.focusedMonitor && root.targetScreen.name === Hyprland.focusedMonitor.name
    target: "launcher"
    function toggle() {
      root.toggle();
    }
    function open() {
      if (!root.visible)
        root.toggle();
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
  WlrLayershell.namespace: "crux-launcher"
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

  // 660 wide, centred; apps-only launcher today (no run/windows/calc modes, so no EXEC/FOCUS distinction).
  Item {
    id: card
    anchors.centerIn: parent
    width: 660
    // Fixed height, not content-sized: DesktopEntries loads async, so contentHeight-driven sizing kept
    // changing after the Chamfer background had already rendered.
    // Logs a bounded handful of Chamfer "binding loop" warnings at startup (Shape/PathPolyline settling) — harmless.
    height: 560

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutTopLeft: false
      cutTopRight: true
      cutBottomLeft: true
      cutBottomRight: false
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
      spacing: 0

      // ---- Input row ----
      RowLayout {
        id: headerRow
        Layout.fillWidth: true
        Layout.preferredHeight: 56
        Layout.leftMargin: 18
        Layout.rightMargin: 18
        spacing: 10

        Text {
          text: ">"
          color: Color.primary
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodyLgSize
          font.weight: Font.DemiBold
        }

        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: Tokens.bodyLgSize + 4

          TextInput {
            id: searchInput
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(1, implicitWidth)
            text: root.query
            onTextChanged: root.query = text
            color: Color.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodyLgSize

            Text {
              visible: searchInput.text === ""
              text: "search apps…"
              color: Color.labelText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodyLgSize
            }

            Rectangle {
              visible: searchInput.activeFocus
              anchors.left: parent.right
              anchors.leftMargin: 2
              anchors.verticalCenter: parent.verticalCenter
              width: 2
              height: 17 // spec §6.2: "2px×17px primary caret" — a fixed dimension, not tied to body-lg's 15px
              color: Color.primary

              SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation {
                  to: 0
                  duration: 500
                }
                NumberAnimation {
                  to: 1
                  duration: 500
                }
              }
            }

            Keys.onDownPressed: root.selectedIndex = Math.min(root.results.length - 1, root.selectedIndex + 1)
            Keys.onUpPressed: root.selectedIndex = Math.max(0, root.selectedIndex - 1)
            Keys.onReturnPressed: root.execMode ? root.runExecCommand() : root.launch(root.results[root.selectedIndex])
          }
        }

        Text {
          text: root.execMode ? "RUN" : String(root.results.length).padStart(2, "0") + " MATCHES"
          color: root.execMode ? Color.primary : Color.labelText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.labelXsSize
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Color.surfaceContainerHigh
      }

      // ---- Exec mode hint (shown instead of the results list) ----
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.execMode

        Text {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.margins: 18
          text: root.execCommand.trim() === "" ? "Type a command to run…" : "⏎  sh -c \"" + root.execCommand + "\""
          color: root.execCommand.trim() === "" ? Color.labelText : Color.surfaceText
          font.family: Tokens.fontFamily
          font.pixelSize: Tokens.bodySize
          wrapMode: Text.WordWrap
          width: parent.width - 36
        }
      }

      // ---- Results ----
      ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        visible: !root.execMode
        model: root.results
        currentIndex: root.selectedIndex

        delegate: Item {
          id: rowItem
          required property var modelData
          required property int index
          readonly property bool selected: index === root.selectedIndex
          readonly property string execPath: rowItem.modelData.command && rowItem.modelData.command.length > 0 ? rowItem.modelData.command[0] : ""
          width: ListView.view.width
          height: 48

          Rectangle {
            anchors.fill: parent
            color: rowItem.selected ? Color.primaryContainer : "transparent"
          }

          Rectangle {
            visible: rowItem.selected
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2
            color: Color.primary
          }

          Rectangle {
            visible: !rowItem.selected
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Color.surfaceContainerHigh
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 14

            Text {
              text: String(rowItem.index + 1).padStart(2, "0")
              color: rowItem.selected ? Color.primaryContainerText : Color.labelText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.labelXsSize
              font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
            }

            Item {
              Layout.preferredWidth: 22
              Layout.preferredHeight: 22

              // Fixed-size wrapper, not Layout.* directly on the Shape — avoids an infinite "_points" binding loop.
              Chamfer {
                anchors.fill: parent
                chamferSize: Tokens.chamferIcon
                cutTopRight: true
                cutBottomLeft: true
                fillColor: rowItem.selected ? Color.primary : "transparent"
                strokeColor: rowItem.selected ? Color.primary : Color.outline
                strokeWidth: 1
              }

              // DesktopEntry.icon is a bare icon-theme name, not a path — Quickshell.iconPath() resolves it via the icon theme.
              IconImage {
                anchors.centerIn: parent
                anchors.margins: 2
                width: 16
                height: 16
                asynchronous: true
                source: rowItem.modelData.icon ? Quickshell.iconPath(rowItem.modelData.icon, "application-x-executable") : ""
              }
            }

            Text {
              text: rowItem.modelData.name || ""
              color: rowItem.selected ? Color.primaryContainerText : Color.surfaceText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.bodySize
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Text {
              text: rowItem.execPath
              color: rowItem.selected ? Color.primaryContainerText : Color.labelText
              font.family: Tokens.fontFamily
              font.pixelSize: Tokens.captionSize
              font.letterSpacing: Tokens.captionSize * Tokens.captionTracking
              elide: Text.ElideLeft
              Layout.maximumWidth: 220
              horizontalAlignment: Text.AlignRight
            }
          }

          HoverHandler {
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: root.launch(rowItem.modelData)
          }
        }
      }

      // ---- Footer ----
      Rectangle {
        id: footer
        Layout.fillWidth: true
        Layout.preferredHeight: 40
        color: Color.surfaceContainerLow

        Row {
          anchors.centerIn: parent
          spacing: 18

          Text {
            text: "↑↓ MOVE"
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }
          Text {
            text: "⏎ LAUNCH"
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }
          Text {
            text: "ESC CLOSE"
            color: Color.labelText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
          }
        }
      }
    }
  }
}
