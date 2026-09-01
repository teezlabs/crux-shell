import QtQuick
import qs.Commons
import qs.Modules.Bar.Extras

// The bar's content: three sections (left/center/right) of widgets, laid out
// according to the per-screen widget list in Settings.
Item {
  id: root

  property var screen: null
  property bool vertical: false
  // See BarSection.qml's contentVertical doc comment — governs each
  // widget's own internal layout independently of the bar's true
  // orientation, so a "top"/"bottom" bar on a portrait-rotated screen still
  // gets the compact/stacked widget content a real vertical bar uses.
  property bool contentVertical: vertical
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
    contentVertical: root.contentVertical
    widgetsModel: root.barWidgets.left
    dragState: dragState
  }

  // Centered on its own *visible* content, not the box including the
  // trailing drop-zone (see BarSection.qml's trailingSize) — otherwise the
  // invisible zone's width skews the real widgets off true-center by half
  // its size. trailingSize only ever applies on the section's *main* axis
  // (horizontal when the bar is horizontal, vertical when it's a side bar)
  // — applying it to both x and y unconditionally was a real bug: it threw
  // off the *cross*-axis centering too (the module visibly dropped out of
  // vertical center on a horizontal bar), since trailingSize has nothing to
  // do with how the module centers across the bar's own thickness.
  BarSection {
    id: centerSection
    x: root.vertical ? (root.width - width) / 2 : (root.width - width + centerSection.trailingSize) / 2
    y: root.vertical ? (root.height - height + centerSection.trailingSize) / 2 : (root.height - height) / 2
    section: "center"
    screen: root.screen
    vertical: root.vertical
    contentVertical: root.contentVertical
    widgetsModel: root.barWidgets.center
    dragState: dragState
  }

  // Always pinned to the true far screen edge — an earlier "pull toward
  // center when the gap looks big" clamp (maxSectionGap) actively worked
  // against this on wider screens: it compared the true edge-anchored
  // position against centerSection's edge plus a fixed budget and picked
  // whichever was smaller, which on a roomy monitor meant the smaller
  // (more-central, short-of-the-edge) position won even though there was
  // plenty of room to just hug the edge. A right-aligned bar group should
  // hug the actual edge, full stop — that's the whole point of a
  // right-aligned group.
  //
  // Shifted right/down by trailingSize so the *visible* last widget (not
  // the invisible trailing drop-zone tacked on after it) is what actually
  // touches contentPadding from the true edge — see BarSection.qml's
  // trailingSize doc comment. This lets the drop-zone's tail hang slightly
  // past the window's own edge, which is fine: it's not visible and isn't
  // the only way to drop a widget at the end of the list.
  BarSection {
    id: rightSection
    x: root.vertical ? (root.width - width) / 2 : root.width - width - Settings.data.bar.contentPadding + rightSection.trailingSize
    y: root.vertical ? root.height - height - Settings.data.bar.contentPadding + rightSection.trailingSize : (root.height - height) / 2
    section: "right"
    screen: root.screen
    vertical: root.vertical
    contentVertical: root.contentVertical
    widgetsModel: root.barWidgets.right
    dragState: dragState
  }
}
