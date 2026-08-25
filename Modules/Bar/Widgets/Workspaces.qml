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
  property bool vertical: false

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

  // Cross-axis size fixed at 32 to match every other bar widget's
  // implicitHeight — BarSection's Grid doesn't cross-center children of
  // differing sizes, so a shorter cross-axis size here left this widget's
  // whole bounding box mis-aligned instead of centered in the bar. The
  // main-axis size (implicitWidth horizontal / implicitHeight vertical)
  // still tracks the pills' own total size, same as before. This also
  // fixes a real bug, not just cosmetics: the pill row previously stayed
  // horizontal even in a vertical bar, forcing the whole enclosing section
  // far wider than the bar itself and pushing sibling widgets off-window.
  // row.width/height, not implicitWidth/implicitHeight — see the matching
  // comment in BarSection.qml for why Grid's implicit size properties
  // aren't reliable with the rows:1000/columns:1000 trick used below.
  implicitWidth: root.vertical ? 32 : row.width
  implicitHeight: root.vertical ? row.height : 32
  width: implicitWidth
  height: implicitHeight

  // Grid rather than Row/Column so one type covers both bar orientations —
  // see the same trick/comment in BarSection.qml.
  Grid {
    id: row
    anchors.centerIn: parent
    spacing: 4
    flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
    rows: root.vertical ? 1000 : 1
    columns: root.vertical ? 1 : 1000

    Repeater {
      model: root.wsModel

      // noctalia's own workspace-pill look (Modules/Bar/Extras/WorkspacePill.qml
      // there): every workspace is a filled, fully-rounded pill; the focused
      // one grows along the bar's main axis with a springy OutBack animation
      // rather than changing shape. No skew/gradient/glow — the size change
      // and the solid accent fill are what carry it.
      delegate: Item {
        id: wsDelegate
        required property int wsId
        required property string name
        required property bool active

        readonly property int crossSize: 20
        readonly property int mainSizeInactive: 20
        readonly property int mainSizeActive: 32

        width: root.vertical ? crossSize : (active ? mainSizeActive : mainSizeInactive)
        height: root.vertical ? (active ? mainSizeActive : mainSizeInactive) : crossSize

        Behavior on width {
          NumberAnimation {
            duration: Style.animationNormal
            easing.type: Easing.OutBack
          }
        }
        Behavior on height {
          NumberAnimation {
            duration: Style.animationNormal
            easing.type: Easing.OutBack
          }
        }

        Rectangle {
          id: pill
          anchors.fill: parent
          radius: Math.min(width, height) / 2
          color: wsDelegate.active ? Color.mPrimary : (hoverHandler.hovered ? Color.alpha(Color.mPrimary, 0.22) : Color.alpha(Color.mOnSurfaceVariant, 0.18))

          Behavior on color {
            ColorAnimation {
              duration: Style.animationFast
            }
          }
        }

        Text {
          anchors.centerIn: parent
          text: wsDelegate.name
          color: wsDelegate.active ? Color.mOnPrimary : Color.mOnSurfaceVariant
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: 11
          font.bold: wsDelegate.active
        }

        HoverHandler {
          id: hoverHandler
          cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
          acceptedButtons: Qt.LeftButton
          // This box's Hyprland runs a Lua config; legacy dispatch strings
          // like "workspace N" error out silently through Hyprland.dispatch().
          // hyprctl's Lua-shorthand syntax is the form that actually works here.
          onTapped: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + wsDelegate.wsId + " })"])
        }
      }
    }
  }
}
