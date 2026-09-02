import QtQuick
import Quickshell
import qs.Commons
import qs.Modules.Bar.Extras

// Loads one bar widget by id — either a built-in from
// Modules/Bar/Widgets/<id>.qml, or (if no built-in matches) a local plugin's
// Widget.qml via Commons/Plugins.qml — and hands it the per-instance
// context (screen, section, position within section).
Item {
  id: root

  required property string widgetId
  required property var widgetScreen
  required property string section
  required property int sectionWidgetIndex
  // True bar orientation; multi-item grid widgets (Tray, Workspaces) must use this, not the compact flag below.
  property bool vertical: false
  // Compact stacked-text layout: true for a real vertical bar, or a horizontal bar on a portrait screen.
  property bool contentVertical: vertical

  // Set by BarSection.qml — see crux skill's notes.md.
  property bool invertChamfer: false

  // Widgets confirmed to fit a compact 2-3 line stack; Clock deliberately
  // excluded (always single-line). Sound was here too, but stacking grows
  // a widget *taller* — right for a real vertical bar (room along its own
  // long axis), but wrong for a horizontal bar on a portrait screen (the
  // bar's fixed thickness IS its cross-axis, so a taller module just
  // overflows it) — confirmed making the whole horizontal bar look
  // thicker than every other, correctly-sized module next to it.
  readonly property var _compactSafeIds: ["Layout"]
  readonly property bool _effectiveVertical: _compactSafeIds.indexOf(widgetId) !== -1 ? contentVertical : vertical

  readonly property string _widgetsDir: Quickshell.shellDir + "/Modules/Bar/Widgets/"
  readonly property bool _isBuiltin: BarWidgetRegistry.hasWidget(root.widgetId)
  readonly property bool _isPlugin: !_isBuiltin && Plugins.hasWidget(root.widgetId)

  // No anchors.fill on the Loader: an explicit size on the Loader forces the
  // loaded item down to that size (0x0 before the first item loads), which
  // was collapsing every widget's real hit-test area to a point.
  implicitWidth: loader.item ? loader.item.implicitWidth : 0
  implicitHeight: loader.item ? loader.item.implicitHeight : 0
  width: implicitWidth
  height: implicitHeight

  Loader {
    id: loader
    active: root._isBuiltin || root._isPlugin
    source: root._isBuiltin ? root._widgetsDir + root.widgetId + ".qml" : (root._isPlugin ? Plugins.widgetPath(root.widgetId) : "")

    onLoaded: {
      item.screen = root.widgetScreen;
      item.section = root.section;
      item.sectionWidgetIndex = root.sectionWidgetIndex;
      // Guarded: writing an undeclared QML property throws, reading one returns undefined. Bound live (bar position can change at runtime).
      if (item.vertical !== undefined)
        item.vertical = Qt.binding(function () {
          return root._effectiveVertical;
        });
      // Raw portrait-compact flag, distinct from `vertical` above — see
      // ControlCenter.qml / crux skill's notes.md.
      if (item.contentVertical !== undefined)
        item.contentVertical = Qt.binding(function () {
          return root.contentVertical;
        });
      if (item.invertChamfer !== undefined)
        item.invertChamfer = Qt.binding(function () {
          return root.invertChamfer;
        });
    }
  }
}
