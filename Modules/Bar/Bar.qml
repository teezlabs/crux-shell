import QtQuick
import qs.Commons
import qs.Modules.Bar.Extras

// Three sections of widgets from the per-screen widget list in Settings.
Item {
  id: root

  property var screen: null
  property bool vertical: false
  // Compact widget content, also on a horizontal bar on a portrait screen (see BarSection.contentVertical).
  property bool contentVertical: vertical
  readonly property string screenName: screen ? screen.name : ""
  readonly property var barWidgets: Settings.isLoaded ? Settings.getBarWidgetsForScreen(screenName) : ({
                                                                                                          "left": [],
                                                                                                          "center": [],
                                                                                                          "right": []
                                                                                                        })

  anchors.fill: parent

  // Shared by all three sections so a drop can tell which section the drag started in.
  QtObject {
    id: dragState
    property string sourceSection: ""
    property int sourceIndex: -1
    property string targetSection: ""
    property int targetIndex: -1
  }

  // Plain x/y, not anchors (docs/qml-gotchas.md, "Bindings that don't re-run").
  BarSection {
    id: leftSection
    x: root.vertical ? (root.width - width) / 2 : Settings.data.bar.contentPadding + leftSection.groupInset
    y: root.vertical ? Settings.data.bar.contentPadding + leftSection.groupInset : (root.height - height) / 2
    section: "left"
    screen: root.screen
    vertical: root.vertical
    contentVertical: root.contentVertical
    widgetsModel: root.barWidgets.left
    dragState: dragState
  }

  // Centre yields to a growing neighbour instead of being overlapped (docs/design-notes.md, "Bar pills expand").
  readonly property real sectionGap: Settings.data.bar.contentPadding + (Settings.data.bar.groupSections ? Tokens.spaceMd * 2 : 0)

  function clampCenter(ideal, size, leadEnd, trailStart) {
    const lo = leadEnd + root.sectionGap;
    const hi = trailStart - size - root.sectionGap;
    // No room for all three: stay clear of the leading section and let the trailing one win.
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

  // Pinned to the far edge, offset by trailingSize so the last visible widget meets contentPadding.
  BarSection {
    id: rightSection
    x: root.vertical ? (root.width - width) / 2 : root.width - width - Settings.data.bar.contentPadding - rightSection.groupInset + rightSection.trailingSize
    y: root.vertical ? root.height - height - Settings.data.bar.contentPadding - rightSection.groupInset + rightSection.trailingSize : (root.height - height) / 2
    section: "right"
    screen: root.screen
    vertical: root.vertical
    contentVertical: root.contentVertical
    widgetsModel: root.barWidgets.right
    dragState: dragState
  }
}
