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

  // Positioned with plain x/y bindings rather than anchors (anchors.bottom/
  // anchors.centerIn etc) — Qt's anchor system doesn't reliably react when
  // a BarSection's height changes via the _sizeVersion workaround in
  // BarSection.qml (confirmed via console.log: implicitHeight itself
  // settles to the correct value, an anchored bottom/centerIn position
  // computed from it does not, staying stuck using the height from before
  // the workaround kicked in). Plain property bindings read `width`/
  // `height` directly and don't go through that broken path.
  //
  // "left"/"right" section ids stay the same regardless of orientation
  // (Settings.data.bar.widgets is keyed by them either way) — only which
  // screen edge they sit against changes: along the bar's main axis when
  // vertical (top/bottom) instead of across it (left/right).
  BarSection {
    id: leftSection
    x: root.vertical ? (root.width - width) / 2 : Settings.data.bar.contentPadding
    y: root.vertical ? Settings.data.bar.contentPadding : (root.height - height) / 2
    section: "left"
    screen: root.screen
    vertical: root.vertical
    widgetsModel: root.barWidgets.left
    dragState: dragState
  }

  BarSection {
    id: centerSection
    x: (root.width - width) / 2
    y: (root.height - height) / 2
    section: "center"
    screen: root.screen
    vertical: root.vertical
    widgetsModel: root.barWidgets.center
    dragState: dragState
  }

  BarSection {
    id: rightSection
    x: root.vertical ? (root.width - width) / 2 : (root.width - width - Settings.data.bar.contentPadding)
    y: root.vertical ? (root.height - height - Settings.data.bar.contentPadding) : (root.height - height) / 2
    section: "right"
    screen: root.screen
    vertical: root.vertical
    widgetsModel: root.barWidgets.right
    dragState: dragState
  }
}
