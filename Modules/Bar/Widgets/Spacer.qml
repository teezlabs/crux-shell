import QtQuick
import qs.Commons
import qs.Modules.Bar.Extras

// Configurable blank gap. Multi-instance: width comes from this instance's widgetData.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property var widgetData: ({})

  readonly property int defaultSize: 16
  readonly property int size: {
    var w = widgetData && widgetData.width !== undefined ? parseInt(widgetData.width) : NaN;
    return isNaN(w) || w < 0 ? defaultSize : w;
  }

  // Cross-axis matches other modules so the Grid centres it the same way.
  implicitWidth: root.vertical ? Tokens.barModuleHeight : root.size
  implicitHeight: root.vertical ? root.size : Tokens.barModuleHeight
  width: implicitWidth
  height: implicitHeight
}
