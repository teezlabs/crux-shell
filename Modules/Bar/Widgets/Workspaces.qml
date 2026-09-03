import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// Workspaces module (spec §6.1): fixed 28px cells, active/occupied/empty color states.
// Per-monitor workspace IDs read from `hyprctl workspacerules -j`, not hardcoded 1-5; falls back to 1-5 if no rule.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false

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
    }

    wsModel.clear();
    for (var i = 0; i < root.assignedIds.length; i++) {
      var n = root.assignedIds[i];
      wsModel.append({
        "wsId": n,
        "occupied": !!occupied[n],
        "active": n === focusedId
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

  BarModule {
    id: module
    vertical: root.vertical
    leftPadding: 4
    rightPadding: 4
    topPadding: 4
    bottomPadding: 4

    // Grid rather than a fixed Row/Column so one delegate set covers both
    // bar orientations — same Grid.TopToBottom/columns:1 <-> Grid.LeftToRight
    // /rows:1 trick BarSection.qml itself uses for the same reason.
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
          required property int index

          readonly property int longSide: 28
          readonly property int shortSide: Tokens.barModuleHeight - 8
          readonly property bool isFirst: index === 0
          readonly property bool isLast: index === root.wsModel.count - 1
          width: root.vertical ? shortSide : longSide
          height: root.vertical ? longSide : shortSide

          // Only first/last cells chamfer, matching the module's outer corners. Which corner goes with
          // "first" flips with orientation (requested after the un-flipped version looked wrong on a vertical bar).
          Chamfer {
            anchors.fill: parent
            visible: cell.active && (cell.isFirst || cell.isLast)
            chamferSize: Tokens.chamferIcon
            cutBottomLeft: root.vertical ? cell.isLast : cell.isFirst
            cutTopRight: root.vertical ? cell.isFirst : cell.isLast
            fillColor: Color.primaryContainer
          }
          Rectangle {
            anchors.fill: parent
            visible: cell.active && !cell.isFirst && !cell.isLast
            color: Color.primaryContainer
          }

          // Active marker: bottom edge inset for a horizontal bar, side
          // edge inset for a vertical one — same "underline" idea rotated
          // onto whichever edge faces the direction workspaces read in.
          Rectangle {
            anchors.bottom: !root.vertical ? parent.bottom : undefined
            anchors.left: root.vertical ? parent.left : parent.left
            anchors.right: !root.vertical ? parent.right : undefined
            anchors.top: root.vertical ? parent.top : undefined
            anchors.topMargin: root.vertical ? 6 : 0
            anchors.bottomMargin: root.vertical ? 6 : 0
            anchors.leftMargin: !root.vertical ? 6 : 0
            anchors.rightMargin: !root.vertical ? 6 : 0
            width: root.vertical ? 2 : undefined
            height: root.vertical ? undefined : 2
            visible: cell.active
            color: Color.primary
          }

          NText {
            tracking: true
            anchors.centerIn: parent
            text: String(cell.wsId)
            color: cell.active ? Color.primaryContainerText : (cell.occupied ? Color.surfaceText : Color.disabledText)
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
