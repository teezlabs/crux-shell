import QtQuick
import Quickshell
import qs.Modules.Bar.Extras

// Loads one bar widget by id from Modules/Bar/Widgets/<id>.qml and hands it
// the per-instance context (screen, section, position within section).
Item {
  id: root

  required property string widgetId
  required property var widgetScreen
  required property string section
  required property int sectionWidgetIndex
  property bool vertical: false

  readonly property string _widgetsDir: Quickshell.shellDir + "/Modules/Bar/Widgets/"

  // No anchors.fill on the Loader: an explicit size on the Loader forces the
  // loaded item down to that size (0x0 before the first item loads), which
  // was collapsing every widget's real hit-test area to a point.
  implicitWidth: loader.item ? loader.item.implicitWidth : 0
  implicitHeight: loader.item ? loader.item.implicitHeight : 0
  width: implicitWidth
  height: implicitHeight

  Loader {
    id: loader
    active: BarWidgetRegistry.hasWidget(root.widgetId)
    source: active ? root._widgetsDir + root.widgetId + ".qml" : ""

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
          return root.vertical;
        });
    }
  }
}
