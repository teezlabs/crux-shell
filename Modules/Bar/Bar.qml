import QtQuick
import qs.Commons
import qs.Modules.Bar.Extras

// The bar's content: three sections (left/center/right) of widgets, laid out
// according to the per-screen widget list in Settings.
Item {
  id: root

  property var screen: null
  readonly property string screenName: screen ? screen.name : ""
  readonly property var barWidgets: Settings.isLoaded ? Settings.getBarWidgetsForScreen(screenName) : ({
                                                                                                          "left": [],
                                                                                                          "center": [],
                                                                                                          "right": []
                                                                                                        })

  anchors.fill: parent

  // Shared across all three sections so a drop in one can read which
  // section the drag started in — lets a widget be dragged between
  // left/center/right, not just reordered within one.
  QtObject {
    id: dragState
    property string sourceSection: ""
    property int sourceIndex: -1
    property string targetSection: ""
    property int targetIndex: -1
  }

  BarSection {
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: 8
    section: "left"
    screen: root.screen
    widgetsModel: root.barWidgets.left
    dragState: dragState
  }

  BarSection {
    anchors.centerIn: parent
    section: "center"
    screen: root.screen
    widgetsModel: root.barWidgets.center
    dragState: dragState
  }

  BarSection {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.rightMargin: 8
    section: "right"
    screen: root.screen
    widgetsModel: root.barWidgets.right
    dragState: dragState
  }
}
