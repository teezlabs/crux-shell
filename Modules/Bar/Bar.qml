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

  // Plain x/y, not anchors — see crux skill's notes.md.
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

  // Centers on visible content only, trailingSize applied on main axis
  // only — see crux skill's notes.md.
  //
  // The three sections are positioned independently, so a section that
  // grows at runtime (an expanding BarPill) used to slide straight over
  // this one. Centre yields instead: it stays centred while there's room
  // and is pushed aside once a neighbour would overlap it.
  readonly property int sectionGap: Settings.data.bar.contentPadding

  function clampCenter(ideal, size, leadEnd, trailStart) {
    const lo = leadEnd + root.sectionGap;
    const hi = trailStart - size - root.sectionGap;
    // Not enough room for all three: keep clear of the leading section and
    // let the trailing one win, rather than centring under both.
    if (hi < lo)
      return lo;
    return Math.max(lo, Math.min(ideal, hi));
  }

  BarSection {
    id: centerSection
    x: root.vertical ? (root.width - width) / 2 : root.clampCenter((root.width - width + centerSection.trailingSize) / 2, width, leftSection.x + leftSection.width, rightSection.x)
    y: root.vertical ? root.clampCenter((root.height - height + centerSection.trailingSize) / 2, height, leftSection.y + leftSection.height, rightSection.y) : (root.height - height) / 2
    section: "center"
    screen: root.screen
    vertical: root.vertical
    contentVertical: root.contentVertical
    widgetsModel: root.barWidgets.center
    dragState: dragState
  }

  // Always pinned to the true far screen edge, shifted by trailingSize so
  // the visible last widget (not the invisible drop-zone) touches
  // contentPadding — see crux skill's notes.md.
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
