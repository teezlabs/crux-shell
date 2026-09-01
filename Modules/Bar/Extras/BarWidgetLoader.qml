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
  // Bar's true physical orientation (only ever true for a real left/right
  // bar) — multi-item grid widgets (Tray, Workspaces) that stack along the
  // bar's own long axis must use this, never the compact flag below, or
  // they overflow past the bar's height with nothing bounding them
  // (confirmed real breakage: Tray's icons did exactly that).
  property bool vertical: false
  // "Render your short text stack instead of one wide line" — true for a
  // real vertical bar too, but also for a horizontal top/bottom bar sitting
  // on a portrait-rotated screen, which has much less width to work with
  // than a normal landscape top bar. Only forwarded to widgets confirmed to
  // actually fit that stack within the bar's thickness (see
  // _compactSafeIds) — everything else keeps using `vertical` above so its
  // layout stays tied to genuine bar orientation.
  property bool contentVertical: vertical

  // Set by BarSection.qml — see crux skill's notes.md.
  property bool invertChamfer: false

  // Confirmed (by screenshot) to fit their compact 2-3 line stack within a
  // modestly bumped bar thickness: Sound (VOL value), Layout (TILE/layout
  // name). Deliberately excludes multi-item widgets (Tray, Workspaces) and
  // anything not yet height-audited (SystemMonitor, StatusGroup, Media) —
  // add to this list only after confirming via a real screenshot that its
  // vertical variant's content actually fits.
  //
  // Clock was here too, but explicitly asked to be dropped: on a
  // horizontal (top/bottom) bar, always show the single-line "WED 26 AUG ·
  // 14:32" format, even on a portrait-rotated screen — only a real
  // vertical (left/right) bar should stack it.
  readonly property var _compactSafeIds: ["Sound", "Layout"]
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
      // Not every widget cares about orientation, so this is only forwarded
      // to ones that declare the property — writing to an undeclared QML
      // property throws, but reading one that doesn't exist just returns
      // undefined, which is what this check relies on. Bound live (unlike
      // screen/section/sectionWidgetIndex above) since bar position can
      // change at runtime via the settings panel, not just at boot.
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
