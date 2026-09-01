import QtQuick
import qs.Commons

// Configurable-width blank gap for manual bar layout. Multi-instance: width lives on this widget's own
// widgetData entry, not a shared Settings singleton (see BarWidgetRegistry.multiInstanceIds).
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

  // Cross-axis matches every other widget's module height so BarSection's
  // Grid cross-centers it the same as everything else; main-axis is the
  // configurable size.
  implicitWidth: root.vertical ? Tokens.barModuleHeight : root.size
  implicitHeight: root.vertical ? root.size : Tokens.barModuleHeight
  width: implicitWidth
  height: implicitHeight
}
