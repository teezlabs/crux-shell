import QtQuick
import Quickshell
import qs.Commons
import qs.Services

// Loads a bar widget by id (built-in Modules/Bar/Widgets/<id>.qml, else a plugin's Widget.qml) and passes its context.
Item {
  id: root

  required property string widgetId
  // This instance's bar.widgets entry, forwarded to widgets that declare widgetData.
  property var widgetData: ({})
  required property var widgetScreen
  required property string section
  required property int sectionWidgetIndex
  // True bar orientation; multi-item grid widgets (Tray, Workspaces) must use this, not the compact flag below.
  property bool vertical: false
  // Compact stacked-text layout: true for a real vertical bar, or a horizontal bar on a portrait screen.
  property bool contentVertical: vertical

  // Set by BarSection.qml (docs/design-notes.md, "Chamfer inversion accent").
  property bool invertChamfer: false

  // Widgets that fit a compact stack within a horizontal bar's thickness on a portrait screen.
  readonly property var _compactSafeIds: ["Layout"]
  readonly property bool _effectiveVertical: _compactSafeIds.indexOf(widgetId) !== -1 ? contentVertical : vertical

  readonly property string _widgetsDir: Quickshell.shellDir + "/Modules/Bar/Widgets/"
  readonly property bool _isBuiltin: BarWidgetRegistry.hasWidget(root.widgetId)
  readonly property bool _isPlugin: !_isBuiltin && Plugins.hasWidget(root.widgetId)

  // No anchors.fill on the Loader: an explicit size forces the item to 0x0 before it loads and kills its hit area.
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
      // Raw portrait-compact flag, distinct from vertical.
      if (item.contentVertical !== undefined)
        item.contentVertical = Qt.binding(function () {
          return root.contentVertical;
        });
      if (item.widgetData !== undefined)
        item.widgetData = Qt.binding(function () {
          return root.widgetData;
        });
      if (item.invertChamfer !== undefined)
        item.invertChamfer = Qt.binding(function () {
          return root.invertChamfer;
        });
    }
  }
}
