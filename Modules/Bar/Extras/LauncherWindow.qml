import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Modules.Bar.Extras

// App launcher popup. Uses Quickshell's built-in DesktopEntries singleton
// (DesktopEntries.applications.values) — the same proven data source
// noctalia's Modules/Panels/Launcher/Providers/ApplicationsProvider.qml
// uses — rather than scanning .desktop files by hand. Simple substring
// search rather than porting a fuzzy-match library; good enough to find an
// app by name fast.
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

  readonly property var results: {
    var q = query.trim().toLowerCase();
    var list = allApps;
    if (q !== "") {
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
    return list.slice(0, 30);
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

  // Screen-specific target so a keybind can reach *this* screen's instance
  // specifically (via bin/crux-focused-ipc, which resolves the currently
  // focused monitor) instead of always hitting whichever screen owns the
  // generic "launcher" name below — confirmed real bug: SUPER+A always
  // opened the launcher on screens[0] regardless of which monitor was
  // actually focused. No `enabled` gate needed since the name itself is
  // already unique per screen.
  IpcHandler {
    target: "launcher_" + (root.targetScreen ? root.targetScreen.name : "0")
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

  // A plain "launcher" alias on just one instance, purely so a script or
  // keybind that doesn't know/care which screen it's on still has something
  // simple to call.
  IpcHandler {
    enabled: root.targetScreen === Quickshell.screens[0]
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

  // v2 spec §6.2: 660 wide, centred. Input row 56px ("> " prompt in
  // primary, query at body-lg, 2px cyan caret, "NN MATCHES" right-aligned
  // label-xs). Rows 48px: 2-digit index (label-xs), 18px chamfered icon
  // (filled primary when selected, outline otherwise), name, right-aligned
  // path in grey — crux's launcher is apps-only today (no run/windows/calc
  // modes yet, so no EXEC/FOCUS distinction to make; every row shows its
  // real exec path). Footer 40px on surfaceContainerLow.
  Item {
    id: card
    anchors.centerIn: parent
    width: 660
    // Fixed height rather than sized to content: the app list loads
    // asynchronously (DesktopEntries populating), so a height computed from
    // list.contentHeight kept changing after the card (and its Chamfer
    // background) had already rendered. The list absorbs the fixed space
    // instead (Layout.fillHeight below).
    //
    // Even with a fixed height, boot still logs a handful of "binding loop
    // detected for property _points" warnings from this card's Chamfer at
    // startup (Shape/PathPolyline settling during first layout — same
    // symptom class documented in the crux skill's Grid-staleness gotchas)
    // — confirmed bounded (log stops growing, CPU stays idle) and the panel
    // renders and functions correctly despite it. Revisit if it ever stops
    // settling.
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
            Keys.onReturnPressed: root.launch(root.results[root.selectedIndex])
          }
        }

        Text {
          text: String(root.results.length).padStart(2, "0") + " MATCHES"
          color: Color.labelText
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

      // ---- Results ----
      ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
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

              // Wrapped in a fixed-size Item rather than setting Layout.*
              // directly on the Shape — a Shape's own implicit sizing
              // (derived from its rendered path, which is itself derived
              // from width/height here) fights the Layout-assigned width
              // when there's no anchors.fill in between, producing an
              // infinite "_points" binding loop. Every other Chamfer in
              // the app already goes through a sized wrapper; this was
              // the one spot that didn't.
              Chamfer {
                anchors.fill: parent
                chamferSize: Tokens.chamferIcon
                cutTopRight: true
                cutBottomLeft: true
                fillColor: rowItem.selected ? Color.primary : "transparent"
                strokeColor: rowItem.selected ? Color.primary : Color.outline
                strokeWidth: 1
              }

              // Real per-app icon: DesktopEntry.icon is a bare icon-theme
              // name (the Icon= value straight out of the .desktop file),
              // not a usable path — Quickshell.iconPath() resolves it
              // through the installed icon theme the same way a taskbar
              // would (confirmed against noctalia-shell's own launcher,
              // Commons/ThemeIcons.qml, which does the same lookup).
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
