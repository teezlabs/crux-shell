import QtQuick
import QtQuick.Effects
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

      delegate: Item {
        id: wsDelegate
        required property int wsId
        required property string name
        required property bool active

        width: 22
        height: 22

        // Inactive pills stay plain rounded squares; the active one becomes
        // a skewed parallelogram — a deliberate nod to skwd's signature
        // "everything's a parallelogram" geometry, kept to just the active
        // indicator rather than applied shell-wide so workspace numbers
        // stay legible. Drawn on Canvas (an actual slanted polygon) rather
        // than an Item transform: skewing via Matrix4x4 would skew the
        // number Text too, and getting a shear matrix's axis/sign right
        // without visually testing it felt like a worse use of time than
        // just drawing the four points directly.
        Rectangle {
          anchors.fill: parent
          visible: !wsDelegate.active
          radius: 4
          color: "transparent"
          border.color: Color.mOutline
          border.width: 1
        }

        Canvas {
          id: activeShape
          anchors.fill: parent
          anchors.margins: -2
          visible: wsDelegate.active
          readonly property color c1: Color.mPrimary
          readonly property color c2: Qt.lighter(Color.mPrimary, 1.35)
          onC1Changed: requestPaint()
          onC2Changed: requestPaint()
          onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var skew = width * 0.18;
            var grad = ctx.createLinearGradient(0, 0, width, height);
            grad.addColorStop(0, c2);
            grad.addColorStop(1, c1);
            ctx.fillStyle = grad;
            ctx.beginPath();
            ctx.moveTo(skew, 0);
            ctx.lineTo(width, 0);
            ctx.lineTo(width - skew, height);
            ctx.lineTo(0, height);
            ctx.closePath();
            ctx.fill();
          }
        }

        // Soft glow behind the active shape — reinforces it as "current"
        // beyond just the fill color, and is the one place on the bar this
        // session's styling pass adds an outright glow rather than a flat
        // hover fill.
        MultiEffect {
          anchors.fill: activeShape
          source: activeShape
          visible: wsDelegate.active
          shadowEnabled: true
          shadowColor: Color.mPrimary
          shadowBlur: 0.6
          shadowOpacity: 0.7
          shadowScale: 1
        }

        Text {
          anchors.centerIn: parent
          text: wsDelegate.name
          color: wsDelegate.active ? Color.mOnPrimary : Color.mOnSurface
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: 12
        }

        HoverHandler {
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
