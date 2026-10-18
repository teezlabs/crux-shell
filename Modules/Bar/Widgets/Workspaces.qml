import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import qs.Widgets
import qs.Modules.Bar.Extras

// Workspaces (spec §6.1). Per-monitor ids come from `hyprctl workspacerules -j`, falling back to 1-5.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property bool invertChamfer: false

  readonly property string screenName: screen ? screen.name : ""
  property ListModel wsModel: ListModel {}
  property var assignedIds: [1, 2, 3, 4, 5]

  Process {
    id: rulesProc
    command: ["hyprctl", "workspacerules", "-j"]
    stdout: StdioCollector {
      id: rulesCollector
      waitForEnd: true
    }
    onExited: exitCode => {
      try {
        var rules = JSON.parse(rulesCollector.text);
        var ids = [];
        for (var i = 0; i < rules.length; i++) {
          var rule = rules[i];
          if (!rule || !rule.monitor || rule.monitor.toLowerCase() !== root.screenName.toLowerCase())
            continue;
          var id = parseInt(rule.workspaceString);
          if (!isNaN(id))
            ids.push(id);
        }
        if (ids.length > 0) {
          ids.sort((a, b) => a - b);
          root.assignedIds = ids;
          root.refresh();
        }
      } catch (e) {}
    }
  }

  function refresh() {
    var values = Hyprland.workspaces && Hyprland.workspaces.values ? Hyprland.workspaces.values : [];
    var occupied = {};
    var focusedId = -1;
    var shownId = -1;
    for (var i = 0; i < values.length; i++) {
      var ws = values[i];
      if (!ws || (ws.name && ws.name.indexOf("special:") === 0))
        continue;
      var monitorName = ws.monitor && ws.monitor.name ? ws.monitor.name : "";
      if (monitorName.toLowerCase() !== screenName.toLowerCase())
        continue;
      occupied[ws.id] = true;
      if (ws.focused === true)
        focusedId = ws.id;
      if (ws.active === true)
        shownId = ws.id;
    }

    wsModel.clear();
    for (var i = 0; i < root.assignedIds.length; i++) {
      var n = root.assignedIds[i];
      wsModel.append({
        "wsId": n,
        "occupied": !!occupied[n],
        "active": n === focusedId,
        "shown": n === shownId
      });
    }
  }

  function _deferredRefresh() {
    Qt.callLater(refresh);
  }

  Component.onCompleted: {
    Hyprland.refreshWorkspaces();
    Qt.callLater(refresh);
    rulesProc.running = true;
  }

  Connections {
    target: Hyprland.workspaces
    function onValuesChanged() {
      root._deferredRefresh();
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      Hyprland.refreshWorkspaces();
      root._deferredRefresh();
    }
  }

  implicitWidth: module.implicitWidth
  implicitHeight: module.implicitHeight
  width: implicitWidth
  height: implicitHeight

  // On the floating pill the group plates are hidden; workspaces keep an outline of their own instead of a hover fill.
  Chamfer {
    anchors.fill: module
    visible: Tokens.barPill
    chamferSize: Tokens.chamferGroupedCell
    cutTopRight: true
    cutBottomLeft: true
    strokeColor: Colors.outlineVariant
    strokeWidth: Tokens.borderModule
  }

  BarModule {
    id: module
    invertChamfer: root.invertChamfer
    vertical: root.vertical
    hoverable: !Tokens.barPill
    leftPadding: 4
    rightPadding: 4
    topPadding: 4
    bottomPadding: 4

    // Grid covers both bar orientations, as in BarSection.
    Grid {
      flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
      rows: root.vertical ? 1000 : 1
      columns: root.vertical ? 1 : 1000
      spacing: 0

      Repeater {
        model: root.wsModel

        delegate: Item {
          id: cell
          required property int wsId
          required property bool occupied
          required property bool active
          // Visible on this monitor, focused or not.
          required property bool shown
          required property int index

          readonly property int longSide: 28
          readonly property int shortSide: Tokens.barModuleHeight - 8
          readonly property bool isFirst: index === 0
          readonly property bool isLast: index === root.wsModel.count - 1
          width: root.vertical ? shortSide : longSide
          height: root.vertical ? longSide : shortSide

          // Only the end cells chamfer, matching the module's corners; the highlight cross-fades between cells.
          Chamfer {
            anchors.fill: parent
            opacity: cell.active && (cell.isFirst || cell.isLast) ? 1 : 0
            visible: opacity > 0
            chamferSize: Tokens.chamferIcon
            cutBottomLeft: root.vertical ? cell.isLast : cell.isFirst
            cutTopRight: root.vertical ? cell.isFirst : cell.isLast
            fillColor: Colors.primaryContainer

            Behavior on opacity {
              NumberAnimation {
                duration: Tokens.durationWorkspaceMarker
                easing.type: Tokens.easingWorkspaceMarker
              }
            }
          }
          Rectangle {
            anchors.fill: parent
            opacity: cell.active && !cell.isFirst && !cell.isLast ? 1 : 0
            visible: opacity > 0
            color: Colors.primaryContainer

            Behavior on opacity {
              NumberAnimation {
                duration: Tokens.durationWorkspaceMarker
                easing.type: Tokens.easingWorkspaceMarker
              }
            }
          }

          // Active marker on the edge facing the reading direction.
          Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: !root.vertical ? parent.right : undefined
            anchors.top: root.vertical ? parent.top : undefined
            anchors.topMargin: root.vertical ? 6 : 0
            anchors.bottomMargin: root.vertical ? 6 : 0
            anchors.leftMargin: !root.vertical ? 6 : 0
            anchors.rightMargin: !root.vertical ? 6 : 0
            width: root.vertical ? Tokens.borderMarker : undefined
            height: root.vertical ? undefined : Tokens.borderMarker
            opacity: cell.shown ? 1 : 0
            visible: opacity > 0
            color: Colors.primary

            Behavior on opacity {
              NumberAnimation {
                duration: Tokens.durationWorkspaceMarker
                easing.type: Tokens.easingWorkspaceMarker
              }
            }
          }

          NText {
            tracking: true
            anchors.centerIn: parent
            text: String(cell.wsId)
            color: cell.active ? Colors.primaryContainerText : (cell.shown ? Colors.primary : (cell.occupied ? Colors.surfaceText : Colors.disabledText))
            font.weight: cell.shown ? Font.DemiBold : tierWeight
          }

          HoverHandler {
            cursorShape: Qt.PointingHandCursor
          }

          TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + cell.wsId + " })"])
          }
        }
      }
    }
  }
}
