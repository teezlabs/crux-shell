import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// Focused window's app name + title, via ToplevelManager.activeToplevel (Hyprland-only, no hyprctl needed).
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false

  readonly property var activeToplevel: ToplevelManager.activeToplevel
  readonly property string appId: activeToplevel ? (activeToplevel.appId || "") : ""
  readonly property string windowTitle: activeToplevel ? (activeToplevel.title || "") : ""
  // Clean app name from a reverse-DNS-ish appId (e.g. "org.kde.dolphin" ->
  // "Dolphin"), same rule noctalia's CompositorService.getCleanAppName uses.
  readonly property string appName: {
    var last = appId.split(".").pop() || "";
    if (last === "")
      return "";
    return last.charAt(0).toUpperCase() + last.slice(1);
  }
  readonly property bool hasWindow: activeToplevel !== null && windowTitle !== ""

  implicitWidth: module.implicitWidth
  implicitHeight: module.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarModule {
    id: module
    vertical: root.vertical
    topPadding: 8
    bottomPadding: 8

    NText {
      visible: !root.vertical
      width: Math.min(200, implicitWidth)
      elide: Text.ElideRight
      text: root.hasWindow ? (root.appName !== "" ? root.appName + " — " + root.windowTitle : root.windowTitle) : "Desktop"
      color: root.hasWindow ? Color.surfaceText : Color.surfaceTextMuted
      size: NText.Size.BodySm
    }

    // Vertical bar: no room for a scrolling title — just the app's
    // initial, same compact-stack philosophy every other text widget uses
    // once rotated onto a side bar.
    Column {
      visible: root.vertical
      spacing: 8
      NText {
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: root.hasWindow ? (root.appName !== "" ? root.appName.charAt(0) : "•") : "—"
        color: root.hasWindow ? Color.surfaceText : Color.surfaceTextMuted
        size: NText.Size.LabelXs
        font.weight: Font.DemiBold
      }
    }
  }

  HoverHandler {
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: if (root.activeToplevel)
      root.activeToplevel.activate()
  }
}
