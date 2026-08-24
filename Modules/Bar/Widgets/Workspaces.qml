import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Commons

// Per-monitor workspace switcher. Mirrors noctalia-shell's
// Services/Compositor/HyprlandService.qml workspace-tracking mechanism
// (Modules/Bar/Widgets/Workspace.qml is the widget on top of it) — a real
// ListModel rebuilt via Qt.callLater-deferred updates, not a plain JS array,
// since Repeater/ListModel role bindings are what actually stay reactive here.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1

  readonly property string screenName: screen ? screen.name : ""
  property ListModel wsModel: ListModel {}

  function refresh() {
    var values = Hyprland.workspaces && Hyprland.workspaces.values ? Hyprland.workspaces.values : [];
    var out = [];
    for (var i = 0; i < values.length; i++) {
      var ws = values[i];
      if (!ws || (ws.name && ws.name.indexOf("special:") === 0))
        continue;
      var monitorName = ws.monitor && ws.monitor.name ? ws.monitor.name : "";
      if (monitorName.toLowerCase() !== screenName.toLowerCase())
        continue;
      out.push({
        "wsId": ws.id,
        "name": ws.name || String(ws.id),
        // "focused" is true for exactly one workspace system-wide (whichever
        // monitor currently has keyboard focus) — that's the single global
        // highlight we want, unlike "active" which is true per-monitor.
        "active": ws.focused === true
      });
    }
    out.sort(function (a, b) {
      return a.wsId - b.wsId;
    });

    wsModel.clear();
    for (var j = 0; j < out.length; j++) {
      wsModel.append(out[j]);
    }
  }

  // Deferred so a rawEvent's refreshWorkspaces() (which itself triggers
  // onValuesChanged synchronously) doesn't cause a double rebuild.
  function _deferredRefresh() {
    Qt.callLater(refresh);
  }

  Component.onCompleted: {
    Hyprland.refreshWorkspaces();
    Qt.callLater(refresh);
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
      // A plain focus switch mutates active/focused on the existing workspace
      // objects in place — that's not a structural list change, so
      // Hyprland.workspaces.onValuesChanged never fires for it. Schedule the
      // refresh directly instead of relying solely on that signal.
      Hyprland.refreshWorkspaces();
      root._deferredRefresh();
    }
  }

  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight
  width: implicitWidth
  height: implicitHeight

  Row {
    id: row
    anchors.centerIn: parent
    spacing: 4

    Repeater {
      model: root.wsModel

      delegate: Rectangle {
        id: wsDelegate
        required property int wsId
        required property string name
        required property bool active

        width: 22
        height: 22
        radius: 4
        color: active ? Color.mPrimary : "transparent"
        border.color: Color.mOutline
        border.width: active ? 0 : 1

        Text {
          anchors.centerIn: parent
          text: wsDelegate.name
          color: wsDelegate.active ? Color.mSurface : Color.mOnSurface
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: 12
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          // This box's Hyprland runs a Lua config; legacy dispatch strings
          // like "workspace N" error out silently through Hyprland.dispatch().
          // hyprctl's Lua-shorthand syntax is the form that actually works here.
          onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + wsDelegate.wsId + " })"])
        }
      }
    }
  }
}
