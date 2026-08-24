import QtQuick
import qs.Commons
import qs.Modules.Bar.Extras

// The bar's content: three sections (left/center/right) of widgets, laid out
// according to the per-screen widget list in Settings.
Item {
  id: root

  property var screen: null
  property bool vertical: false
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

  // "left"/"right" sections keep those ids regardless of bar orientation
  // (Settings.data.bar.widgets is keyed by them either way) — only which
  // screen edge they anchor to changes: along the bar's main axis when
  // vertical (top/bottom) instead of across it (left/right).
  BarSection {
    anchors.left: root.vertical ? undefined : parent.left
    anchors.top: root.vertical ? parent.top : undefined
    anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
    anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
    anchors.leftMargin: root.vertical ? 0 : 8
    anchors.topMargin: root.vertical ? 8 : 0
    section: "left"
    screen: root.screen
    vertical: root.vertical
    widgetsModel: root.barWidgets.left
    dragState: dragState
  }

  BarSection {
    anchors.centerIn: parent
    section: "center"
    screen: root.screen
    vertical: root.vertical
    widgetsModel: root.barWidgets.center
    dragState: dragState
  }

  BarSection {
    anchors.right: root.vertical ? undefined : parent.right
    anchors.bottom: root.vertical ? parent.bottom : undefined
    anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
    anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
    anchors.rightMargin: root.vertical ? 0 : 8
    anchors.bottomMargin: root.vertical ? 8 : 0
    section: "right"
    screen: root.screen
    vertical: root.vertical
    widgetsModel: root.barWidgets.right
    dragState: dragState
  }
}
