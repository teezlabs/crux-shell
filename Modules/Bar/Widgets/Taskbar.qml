import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Modules.Bar.Extras

// Running-apps strip via ToplevelManager (same source as ActiveWindow.qml), filtered to the current monitor.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false

  // Only show windows actually present on this widget's monitor — a
  // taskbar showing every window on every screen would duplicate entries
  // across a multi-monitor bar.
  property var windowsList: []

  function refresh() {
    var vals = ToplevelManager.toplevels ? ToplevelManager.toplevels.values : [];
    var out = [];
    for (var i = 0; i < vals.length; i++) {
      var t = vals[i];
      if (!t)
        continue;
      var onThisScreen = true;
      if (root.screen && t.screens) {
        onThisScreen = false;
        for (var j = 0; j < t.screens.length; j++) {
          if (t.screens[j] === root.screen) {
            onThisScreen = true;
            break;
          }
        }
      }
      if (onThisScreen)
        out.push(t);
    }
    root.windowsList = out;
  }

  Component.onCompleted: refresh()

  Connections {
    target: ToplevelManager.toplevels
    function onValuesChanged() {
      root.refresh();
    }
  }

  // A toplevel's own `screens` list can change after creation (window
  // moved to another monitor) without the toplevels list itself changing —
  // re-filter on the manager's active-window change too, cheap enough
  // given typical window counts.
  Connections {
    target: ToplevelManager
    function onActiveToplevelChanged() {
      root.refresh();
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

    Grid {
      flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
      rows: root.vertical ? 1000 : 1
      columns: root.vertical ? 1 : 1000
      spacing: 4

      Repeater {
        model: root.windowsList

        delegate: Item {
          id: taskDelegate
          required property var modelData
          readonly property string appId: modelData.appId || ""
          readonly property string title: modelData.title || ""
          readonly property bool active: modelData.activated === true
          readonly property string initial: {
            var s = appId !== "" ? appId : title;
            return s.length > 0 ? s.charAt(0).toUpperCase() : "?";
          }

          width: Tokens.barModuleHeight - 8
          height: Tokens.barModuleHeight - 8

          Chamfer {
            anchors.fill: parent
            chamferSize: Tokens.chamferIcon
            cutTopRight: true
            cutBottomLeft: true
            fillColor: taskDelegate.active ? Color.primaryContainer : (hoverHandler.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer)
            strokeColor: taskDelegate.active ? Color.primary : Color.outlineVariant
            strokeWidth: Tokens.borderModule
          }

          Text {
            anchors.centerIn: parent
            text: taskDelegate.initial
            color: taskDelegate.active ? Color.primaryContainerText : Color.surfaceTextMuted
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.labelXsSize
            font.weight: taskDelegate.active ? Font.DemiBold : Font.Normal
          }

          HoverHandler {
            id: hoverHandler
            cursorShape: Qt.PointingHandCursor
          }

          TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: taskDelegate.modelData.activate()
          }

          TapHandler {
            acceptedButtons: Qt.MiddleButton
            onTapped: taskDelegate.modelData.close()
          }
        }
      }
    }
  }
}
