import QtQuick
import qs.Commons
import qs.Modules.Bar.Extras

// One bar section (left/center/right): lays out its widgets in a line and
// supports long-press-then-drag reordering, including across sections, with
// a visible insertion-point indicator (a thin bar between widgets) while
// dragging — same idea as the drop indicator in noctalia's
// Widgets/NSectionEditor.qml settings-panel reorder UI. The `vertical`
// property (set from Bar.qml, which gets it from the bar's configured
// position) switches the whole section between a horizontal line (top/
// bottom bar) and a vertical one (left/right bar).
//
// Long-press is detected by a non-exclusive TapHandler (a passive grab —
// it does not block the widget's own click handling underneath, so a
// plain click keeps working untouched); once armed, an enabled DragHandler
// takes over the same in-progress press to move the widget. This ONLY
// works if every bar widget's own click handling is also a pointer
// handler (TapHandler/HoverHandler), not a legacy MouseArea — on this
// box's Qt 6.11, a passive ancestor TapHandler never receives ANY event
// (not even a plain press) when a legacy MouseArea sits underneath it,
// contrary to the usual Flickable-steals-from-MouseArea folklore. Every
// Modules/Bar/Widgets/*.qml file's own click handling was converted from
// MouseArea to TapHandler+HoverHandler for this reason — don't reintroduce
// a MouseArea in a bar widget, or its drag reordering silently breaks.
//
// Cross-section support: `dragState` is a single shared object (created
// once in Bar.qml, passed to all three sections) so a drop in one
// section's DropArea can read which *other* section the drag started in.
// Drag.keys/DropArea.keys use one shared key ("crux-bar-widget") rather
// than a per-section one, so drops are accepted across sections too.
//
// The indicator needs to be positioned freely (not locked into the Grid's
// own layout flow), so the root here is a plain Item sizing itself to the
// inner Grid, not the Grid itself.
Item {
  id: sectionRoot

  property string section: ""
  property var screen: null
  property bool vertical: false
  // Distinct from `vertical` above: that one governs the *section's own*
  // module-to-module arrangement (a true left/right bar stacks modules
  // top-to-bottom). This one governs each *widget's internal* content
  // style, and is also true when the bar is nominally "top"/"bottom" but
  // sitting on a portrait-rotated screen — there the bar is still a
  // physically horizontal strip of modules, but each module only has a
  // short screen edge's worth of width to work with, so its content should
  // render the same compact/stacked style a true vertical bar already
  // uses. See shell.qml's screenIsPortrait for the detection.
  property bool contentVertical: vertical
  readonly property string screenName: screen ? screen.name : ""
  property var widgetsModel: []
  required property QtObject dragState

  // Computed directly from the repeater's own items rather than bound to
  // sectionRow (the Grid)'s width/height or implicitWidth/implicitHeight —
  // confirmed via console.log that neither of Grid's own aggregate size
  // properties reliably emit a change notification with the
  // rows:1000/columns:1000 forced-overflow trick used below.
  //
  // Even so, implicitWidth/implicitHeight below can NOT just call these
  // directly as `_mainSize()` — confirmed via further console.log that a
  // QML binding built by looping `repeater.itemAt(i)` and reading each
  // item's width/height does not reliably register those reads as binding
  // dependencies (a fresh *manual* call to the exact same function always
  // returned the correct, up-to-date value; the *binding* using it as its
  // body stayed stuck at the value from its first evaluation forever,
  // proving the value was always computable, just never re-triggered).
  // `_sizeVersion` works around this: every wrapper delegate bumps it on
  // its own onWidthChanged/onHeightChanged (plain Item property changes,
  // which — unlike the loop above — always notify correctly), and reading
  // it here (even though the value itself is unused) is a direct property
  // read on sectionRoot itself, which QML's dependency tracker always
  // picks up reliably, forcing the binding to re-run.
  property int _sizeVersion: 0

  // The end-module chamfer accent (below) must target the last module that
  // actually renders, not just the last entry in the widgets list — a
  // trailing widget hidden by its own logic (e.g. Updates at 0 count with
  // hideOnZero) would otherwise "steal" the accent invisibly, leaving the
  // real visual end (e.g. Sound) looking unstyled. Reads _sizeVersion so it
  // re-picks whenever a widget's rendered size changes.
  readonly property int _lastVisibleIndex: {
    _sizeVersion;
    for (var i = repeater.count - 1; i >= 0; i--) {
      var item = repeater.itemAt(i);
      if (item && (sectionRoot.vertical ? item.height > 0 : item.width > 0))
        return i;
    }
    return repeater.count - 1;
  }

  function _mainSize() {
    var total = 0;
    for (var i = 0; i < repeater.count; i++) {
      var item = repeater.itemAt(i);
      if (item)
        total += (vertical ? item.height : item.width) + sectionRow.spacing;
    }
    total += vertical ? trailingZone.height : trailingZone.width;
    return total;
  }
  function _crossSize() {
    var maxCross = vertical ? trailingZone.width : trailingZone.height;
    for (var i = 0; i < repeater.count; i++) {
      var item = repeater.itemAt(i);
      if (item)
        maxCross = Math.max(maxCross, vertical ? item.width : item.height);
    }
    return maxCross;
  }

  implicitWidth: {
    _sizeVersion;
    return vertical ? _crossSize() : _mainSize();
  }
  implicitHeight: {
    _sizeVersion;
    return vertical ? _mainSize() : _crossSize();
  }
  width: implicitWidth
  height: implicitHeight

  // The trailing drop-zone exists purely so "append to the end" is always a
  // real, droppable target — it isn't visible content. It's counted in
  // implicitWidth/Height (so the Grid actually reserves room for it and
  // DropArea hit-testing works), but a caller edge-anchoring or centering
  // this section around its *visible* widgets — not this invisible tail —
  // needs to subtract it back out, or the last real widget ends up sitting
  // short of the edge by exactly this much. Confirmed bug: Bar.qml's
  // right-section edge-anchor used the full width including this zone,
  // leaving the power button ~30px short of the actual screen edge.
  readonly property real trailingSize: {
    _sizeVersion;
    return (repeater.count > 0 ? sectionRow.spacing : 0) + (vertical ? trailingZone.height : trailingZone.width);
  }

  readonly property bool isDropTarget: dragState.targetSection === section && dragState.sourceSection !== ""

  // Position of the insertion-point indicator along the layout's main axis
  // (x when horizontal, y when vertical).
  function indicatorPos() {
    var idx = dragState.targetIndex;
    if (idx <= 0)
      return 0;
    var before = repeater.itemAt(Math.min(idx, repeater.count) - 1);
    if (!before)
      return 0;
    var beforeMain = sectionRoot.vertical ? (before.y + before.height) : (before.x + before.width);
    return beforeMain + sectionRow.spacing / 2 - 1;
  }

  // Grid rather than Row/Column so one type covers both bar orientations —
  // with columns/rows forced past the item count, Grid.LeftToRight with
  // rows:1 behaves exactly like Row (never wraps to a second row), and
  // Grid.TopToBottom with columns:1 behaves exactly like Column.
  Grid {
    id: sectionRow
    spacing: Settings.data.bar.widgetSpacing
    flow: sectionRoot.vertical ? Grid.TopToBottom : Grid.LeftToRight
    rows: sectionRoot.vertical ? 1000 : 1
    columns: sectionRoot.vertical ? 1 : 1000

    Repeater {
      id: repeater
      model: sectionRoot.widgetsModel
      onCountChanged: sectionRoot._sizeVersion++

      delegate: Item {
        id: wrapper
        required property var modelData
        required property int index

        readonly property bool isDragged: sectionRoot.dragState.sourceSection === sectionRoot.section && sectionRoot.dragState.sourceIndex === index

        width: loader.implicitWidth
        height: loader.implicitHeight
        opacity: isDragged && dragHandler.active ? 0.35 : 1
        onWidthChanged: sectionRoot._sizeVersion++
        onHeightChanged: sectionRoot._sizeVersion++

        DropArea {
          anchors.fill: parent
          keys: ["crux-bar-widget"]
          onEntered: function (drag) {
            if (drag.source && drag.source.objectName === "cruxBarWidgetDrag") {
              sectionRoot.dragState.targetSection = sectionRoot.section;
              sectionRoot.dragState.targetIndex = wrapper.index;
            }
          }
          onExited: {
            if (sectionRoot.dragState.targetSection === sectionRoot.section && sectionRoot.dragState.targetIndex === wrapper.index) {
              sectionRoot.dragState.targetSection = "";
              sectionRoot.dragState.targetIndex = -1;
            }
          }
          onDropped: function (drop) {
            sectionRoot.commitDrop(wrapper.index);
          }
        }

        Item {
          id: draggableContent
          objectName: "cruxBarWidgetDrag"
          width: parent.width
          height: parent.height
          anchors.centerIn: dragHandler.active ? undefined : parent

          Drag.active: dragHandler.active
          Drag.source: draggableContent
          Drag.hotSpot.x: width / 2
          Drag.hotSpot.y: height / 2
          Drag.keys: ["crux-bar-widget"]

          z: dragHandler.active ? 1000 : 0
          scale: dragHandler.active ? 1.05 : 1.0
          Behavior on scale {
            NumberAnimation {
              duration: 120
            }
          }

          BarWidgetLoader {
            id: loader
            widgetId: wrapper.modelData.id || ""
            widgetScreen: sectionRoot.screen
            section: sectionRoot.section
            sectionWidgetIndex: wrapper.index
            vertical: sectionRoot.vertical
            contentVertical: sectionRoot.contentVertical
            // v5 of this rule (see crux skill's notes.md for the full
            // history — v1-v4 are all superseded, don't resurrect them):
            // left keeps the original "only the end-cap inverts" rule;
            // right is the true mirror of that — reverse the sequence AND
            // flip every shape to its own mirror-image, so the end-cap
            // there is now the one NON-inverted module and everything
            // else in the right section inverts.
            invertChamfer: (sectionRoot.section === "left" && wrapper.index === 0) || (sectionRoot.section === "right" && wrapper.index !== sectionRoot._lastVisibleIndex)
          }

          // Non-exclusive: a passive grab that watches for a long press
          // without blocking the widget's own MouseArea from receiving
          // the same press.
          TapHandler {
            id: tapHandler
            acceptedButtons: Qt.LeftButton
            gesturePolicy: TapHandler.DragThreshold
            longPressThreshold: 0.22
            grabPermissions: PointerHandler.CanTakeOverFromItems | PointerHandler.CanTakeOverFromHandlersOfDifferentType
            onLongPressed: {
              sectionRoot.dragState.sourceSection = sectionRoot.section;
              sectionRoot.dragState.sourceIndex = wrapper.index;
            }
          }

          // Only takes over the in-progress press once armed by the long
          // press above — a plain click never reaches drag distance/
          // duration, so this handler never activates and never touches
          // the event.
          DragHandler {
            id: dragHandler
            target: draggableContent
            enabled: sectionRoot.dragState.sourceSection === sectionRoot.section && sectionRoot.dragState.sourceIndex === wrapper.index
            grabPermissions: PointerHandler.CanTakeOverFromItems | PointerHandler.CanTakeOverFromHandlersOfDifferentType
            onActiveChanged: {
              if (!active && sectionRoot.dragState.sourceSection === sectionRoot.section && sectionRoot.dragState.sourceIndex === wrapper.index) {
                // Capture the shared dragState reference and whether we're
                // over a valid drop target *before* calling Drag.drop() —
                // that call synchronously commits the move via
                // Settings.moveBarWidget, which rebuilds this section's
                // Repeater and destroys this very delegate (sectionRoot,
                // wrapper) mid-handler. Anything read after drop() must not
                // touch sectionRoot/wrapper, only the dragState object
                // itself (owned by Bar.qml, so it outlives the delegate).
                var st = sectionRoot.dragState;
                var droppedOnValidTarget = st.targetSection !== "";
                // DragHandler only toggles Drag.active — nothing calls
                // Drag.drop() on release the way MouseArea.onReleased did
                // in the Taskbar.qml pattern this was adapted from. Do it
                // here, or the DropArea underneath never fires onDropped.
                draggableContent.Drag.drop();
                if (!droppedOnValidTarget) {
                  // Dropped nowhere valid — reset.
                  st.sourceSection = "";
                  st.sourceIndex = -1;
                }
              }
            }
          }
        }
      }
    }

    // A trailing drop zone that always exists, sized enough to be a real
    // target, so a section is never actually undroppable — whether it's
    // genuinely empty, or (like center with just the Media widget) every
    // widget in it currently renders at 0×0 because it's conditionally
    // hidden (nothing playing right now).
    Item {
      id: trailingZone
      readonly property bool sectionEmpty: {
        for (var i = 0; i < repeater.count; i++) {
          var item = repeater.itemAt(i);
          if (item && (sectionRoot.vertical ? item.height > 0 : item.width > 0))
            return false;
        }
        return true;
      }
      width: sectionRoot.vertical ? 24 : Math.max(24, sectionEmpty ? 40 : 0)
      height: sectionRoot.vertical ? Math.max(24, sectionEmpty ? 40 : 0) : 24
      onWidthChanged: sectionRoot._sizeVersion++
      onHeightChanged: sectionRoot._sizeVersion++

      DropArea {
        anchors.fill: parent
        keys: ["crux-bar-widget"]
        onEntered: function (drag) {
          if (drag.source && drag.source.objectName === "cruxBarWidgetDrag") {
            sectionRoot.dragState.targetSection = sectionRoot.section;
            sectionRoot.dragState.targetIndex = sectionRoot.widgetsModel.length;
          }
        }
        onExited: {
          if (sectionRoot.dragState.targetSection === sectionRoot.section && sectionRoot.dragState.targetIndex === sectionRoot.widgetsModel.length) {
            sectionRoot.dragState.targetSection = "";
            sectionRoot.dragState.targetIndex = -1;
          }
        }
        onDropped: function (drop) {
          sectionRoot.commitDrop(sectionRoot.widgetsModel.length);
        }
      }
    }
  }

  // Insertion-point indicator: a thin bar showing exactly where the
  // widget will land, positioned between the two widgets it'll sit
  // between (or at the very start/end).
  Rectangle {
    width: sectionRoot.vertical ? (sectionRow.width > 0 ? sectionRow.width : 24) : 2
    height: sectionRoot.vertical ? 2 : (sectionRow.height > 0 ? sectionRow.height : 24)
    radius: 1
    color: Color.primary
    visible: sectionRoot.isDropTarget
    x: sectionRoot.vertical ? 0 : sectionRoot.indicatorPos()
    y: sectionRoot.vertical ? sectionRoot.indicatorPos() : 0
    z: 2000

    SequentialAnimation on opacity {
      running: sectionRoot.isDropTarget
      loops: Animation.Infinite
      NumberAnimation {
        to: 1
        duration: 400
        easing.type: Easing.InOutQuad
      }
      NumberAnimation {
        to: 0.4
        duration: 400
        easing.type: Easing.InOutQuad
      }
    }
  }

  function commitDrop(toIndex) {
    var st = dragState;
    var fromSection = st.sourceSection;
    var fromIndex = st.sourceIndex;
    var toSection = section;
    st.sourceSection = "";
    st.sourceIndex = -1;
    st.targetSection = "";
    st.targetIndex = -1;
    if (fromSection !== "" && !(fromSection === toSection && fromIndex === toIndex)) {
      Settings.moveBarWidget(screenName, fromSection, fromIndex, toSection, toIndex);
    }
  }
}
