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

  readonly property string _widgetsDir: Quickshell.shellDir + "/Modules/Bar/Widgets/"

  implicitWidth: loader.item ? loader.item.implicitWidth : 0
  implicitHeight: loader.item ? loader.item.implicitHeight : 0

  Loader {
    id: loader
    anchors.fill: parent
    active: BarWidgetRegistry.hasWidget(root.widgetId)
    source: active ? root._widgetsDir + root.widgetId + ".qml" : ""

    onLoaded: {
      item.screen = root.widgetScreen;
      item.section = root.section;
      item.sectionWidgetIndex = root.sectionWidgetIndex;
    }
  }
}
