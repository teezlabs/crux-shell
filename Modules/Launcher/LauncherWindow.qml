import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.Commons
import qs.Widgets
import "Calculator.js" as Calculator

// App launcher popup. Uses Quickshell's DesktopEntries singleton rather than scanning .desktop files by hand.
NPanelWindow {
  id: root

  popupName: "launcher"

  // Resets on every open, whichever way it was opened.
  onVisibleChanged: {
    if (!visible)
      return;
    query = "";
    selectedIndex = 0;
    Qt.callLater(function () {
      searchInput.forceActiveFocus();
    });
  }

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
  readonly property string calcResult: root.execMode ? "" : Calculator.evaluate(query)
  readonly property bool calcMode: root.calcResult !== ""
  readonly property int _resultLimit: Settings.isLoaded ? Settings.data.launcher.resultLimit : 30

  readonly property var results: {
    if (root.execMode || root.calcMode)
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
    } else if (Settings.isLoaded && Settings.data.launcher.sortByMostUsed) {
      var counts = root._usageCounts;
      list = list.slice().sort(function (a, b) {
        var ac = counts[a.id] || 0;
        var bc = counts[b.id] || 0;
        if (ac !== bc)
          return bc - ac;
        return (a.name || "").toLowerCase().localeCompare((b.name || "").toLowerCase());
      });
    } else {
      list = list.slice().sort(function (a, b) {
        return (a.name || "").toLowerCase().localeCompare((b.name || "").toLowerCase());
      });
    }
    return list.slice(0, root._resultLimit);
  }

  readonly property var _usageCounts: {
    try {
      return JSON.parse(Settings.data.launcher.appUsageCounts);
    } catch (e) {
      return {};
    }
  }

  function _bumpUsageCount(appId) {
    if (!appId)
      return;
    var counts = root._usageCounts;
    counts[appId] = (counts[appId] || 0) + 1;
    Settings.data.launcher.appUsageCounts = JSON.stringify(counts);
  }

  function runExecCommand() {
    if (root.execCommand.trim() === "")
      return;
    Quickshell.execDetached(["sh", "-c", root.execCommand]);
    root.visible = false;
    root.query = "";
  }

  function copyCalcResult() {
    Quickshell.execDetached(["wl-copy", root.calcResult]);
    Toast.show("Copied " + root.calcResult);
    root.visible = false;
  }

  onQueryChanged: selectedIndex = 0
  onResultsChanged: if (selectedIndex >= results.length)
    selectedIndex = Math.max(0, results.length - 1)

  function launch(app) {
    if (!app)
      return;
    root._bumpUsageCount(app.id);
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

  // 660 wide, centred; apps, run-command and inline calculator; no windows mode.
  Item {
    id: card
    anchors.centerIn: parent
    width: 660
    // Fixed height: DesktopEntries loads asynchronously, and content-driven sizing kept resizing the chamfer.
    height: 560

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutTopLeft: false
      cutTopRight: true
      cutBottomLeft: true
      cutBottomRight: false
      fillColor: Colors.alpha(Colors.surface, Tokens.panelOpacity)
      strokeColor: Colors.outline
      strokeWidth: Tokens.borderPanel
      shadow: true
      rimLight: true
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

        NText {
          text: ">"
          color: Colors.primary
          size: NText.Size.BodyLg
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
            color: Colors.surfaceText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodyLgSize
            // Spec caret (§6.2) below; an empty cursorDelegate is what actually hides the native cursor (docs/design-notes.md).
            cursorVisible: false
            cursorDelegate: Item {}

            NText {
              visible: searchInput.text === ""
              x: 6 // clears the caret Rectangle, which sits right at the edge when empty
              text: "search apps…"
              color: Colors.labelText
              size: NText.Size.BodyLg
            }

            Rectangle {
              visible: searchInput.activeFocus
              anchors.left: parent.right
              anchors.leftMargin: 2
              anchors.verticalCenter: parent.verticalCenter
              width: 2
              height: 17 // spec §6.2: "2px×17px primary caret" — a fixed dimension, not tied to body-lg's 15px
              color: Colors.primary

              SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation {
                  to: 0
                  duration: Tokens.durationCaretBlink
                }
                NumberAnimation {
                  to: 1
                  duration: Tokens.durationCaretBlink
                }
              }
            }

            Keys.onDownPressed: root.selectedIndex = Math.min(root.results.length - 1, root.selectedIndex + 1)
            Keys.onUpPressed: root.selectedIndex = Math.max(0, root.selectedIndex - 1)
            Keys.onReturnPressed: root.execMode ? root.runExecCommand() : root.calcMode ? root.copyCalcResult() : root.launch(root.results[root.selectedIndex])
          }
        }

        NText {
          tracking: true
          text: root.execMode ? "RUN" : root.calcMode ? "CALC" : String(root.results.length).padStart(2, "0") + " MATCHES"
          color: root.execMode || root.calcMode ? Colors.primary : Colors.labelText
          size: NText.Size.LabelXs
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.surfaceContainerHigh
      }

      // ---- Exec mode hint (shown instead of the results list) ----
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.execMode

        NText {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.margins: 18
          text: root.execCommand.trim() === "" ? "Type a command to run…" : "⏎  sh -c \"" + root.execCommand + "\""
          color: root.execCommand.trim() === "" ? Colors.labelText : Colors.surfaceText
          wrapMode: Text.WordWrap
          width: parent.width - 36
        }
      }

      // ---- Calculator result (shown instead of the results list) ----
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: root.calcMode

        Rectangle {
          id: calcRow
          anchors.left: parent.left
          anchors.right: parent.right
          height: 64
          color: Colors.primaryContainer

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 14

            NText {
              text: "= " + root.calcResult
              color: Colors.primaryContainerText
              size: NText.Size.BodyLg
              font.weight: Font.DemiBold
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            NText {
              tracking: true
              text: "⏎ COPY"
              color: Colors.primaryContainerText
              size: NText.Size.LabelXs
            }
          }

          HoverHandler {
            cursorShape: Qt.PointingHandCursor
          }
          TapHandler {
            onTapped: root.copyCalcResult()
          }
        }
      }

      // ---- Results ----
      ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        visible: !root.execMode && !root.calcMode
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
            color: rowItem.selected ? Colors.primaryContainer : "transparent"
          }

          Rectangle {
            visible: rowItem.selected
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 2
            color: Colors.primary
          }

          Rectangle {
            visible: !rowItem.selected
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Colors.surfaceContainerHigh
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 14

            NText {
              tracking: true
              text: String(rowItem.index + 1).padStart(2, "0")
              color: rowItem.selected ? Colors.primaryContainerText : Colors.labelText
              size: NText.Size.LabelXs
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
                fillColor: rowItem.selected ? Colors.primary : "transparent"
                strokeColor: rowItem.selected ? Colors.primary : Colors.outline
                strokeWidth: 1
              }

              // DesktopEntry.icon is a bare icon-theme name, not a path — Quickshell.iconPath() resolves it via the icon theme.
              NIcon {
                anchors.centerIn: parent
                anchors.margins: 2
                width: 16
                height: 16
                asynchronous: true
                colorize: false
                iconName: rowItem.modelData.icon || ""
                fallbackIconName: "application-x-executable"
              }
            }

            NText {
              text: rowItem.modelData.name || ""
              color: rowItem.selected ? Colors.primaryContainerText : Colors.surfaceText
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            NText {
              tracking: true
              text: rowItem.execPath
              color: rowItem.selected ? Colors.primaryContainerText : Colors.labelText
              size: NText.Size.Caption
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
        color: Colors.surfaceContainerLow

        Row {
          anchors.centerIn: parent
          spacing: 18

          NText {
            tracking: true
            text: "↑↓ MOVE"
            color: Colors.labelText
            size: NText.Size.LabelXs
          }
          NText {
            tracking: true
            text: "⏎ LAUNCH"
            color: Colors.labelText
            size: NText.Size.LabelXs
          }
          NText {
            tracking: true
            text: "ESC CLOSE"
            color: Colors.labelText
            size: NText.Size.LabelXs
          }
        }
      }
    }
  }
}
