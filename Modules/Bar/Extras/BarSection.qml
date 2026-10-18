import QtQuick
import qs.Commons
import qs.Widgets

// One bar section (left/center/right): lays out its widgets and handles long-press drag reordering across sections.
Item {
  id: sectionRoot

  property string section: ""
  property var screen: null
  property bool vertical: false
  // Per-widget content style; also true for a horizontal bar on a portrait screen (see docs/design-notes.md, "Portrait-monitor bar").
  property bool contentVertical: vertical
  readonly property string screenName: screen ? screen.name : ""
  property var widgetsModel: []
  required property QtObject dragState

  // Main-axis size summed from the repeater's items; _sizeVersion forces re-evaluation (docs/qml-gotchas.md, "Bindings that don't re-run").
  property int _sizeVersion: 0

  // Index of the last module that actually renders, so a hidden trailing widget doesn't take the end-cap accent.
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
      // Grid skips zero-sized children entirely, spacing included.
      if (item && item.width > 0 && item.height > 0)
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

  // Size of the invisible trailing drop zone; callers aligning to the visible widgets subtract it.
  readonly property real trailingSize: {
    _sizeVersion;
    return (repeater.count > 0 ? sectionRow.spacing : 0) + (vertical ? trailingZone.height : trailingZone.width);
  }

  readonly property bool isDropTarget: dragState.targetSection === section && dragState.sourceSection !== ""

  // Insertion indicator position along the main axis.
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

  // Grouped-section plate: one surface behind the whole section, padded by groupPadding.
  readonly property bool grouped: Settings.isLoaded && Settings.data.bar.groupSections && repeater.count > 0
  // Clamped to the bar's slack, or the plate is clipped by the bar window.
  readonly property real groupPadding: {
    sectionRoot._sizeVersion;
    const p = sectionRoot.parent;
    if (!p)
      return 2;
    const slack = (sectionRoot.vertical ? p.width - sectionRoot.width : p.height - sectionRoot.height) / 2;
    return Math.max(2, Math.min(7, slack - 1));
  }
  // Same as the side padding, so an end widget sits evenly inside the chamfered corner.
  readonly property real groupInset: sectionRoot.grouped ? sectionRoot.groupPadding : 0
  readonly property real _groupMain: (sectionRoot.vertical ? sectionRoot.height : sectionRoot.width) - sectionRoot.trailingSize + sectionRoot.groupInset * 2

  Chamfer {
    visible: sectionRoot.grouped && !Tokens.barPill
    x: sectionRoot.vertical ? -sectionRoot.groupPadding : -sectionRoot.groupInset
    y: sectionRoot.vertical ? -sectionRoot.groupInset : -sectionRoot.groupPadding
    width: sectionRoot.vertical ? sectionRoot.width + sectionRoot.groupPadding * 2 : sectionRoot._groupMain
    height: sectionRoot.vertical ? sectionRoot._groupMain : sectionRoot.height + sectionRoot.groupPadding * 2
    chamferSize: Tokens.chamferModule
    // End-cap accent at section scale; the left section is the mirrored one.
    cutTopLeft: sectionRoot.section === "left"
    cutBottomRight: sectionRoot.section === "left"
    cutTopRight: sectionRoot.section !== "left"
    cutBottomLeft: sectionRoot.section !== "left"
    // One step lighter than the bar strip so the plate reads as raised.
    fillColor: Colors.alpha(Colors.surfaceContainerHigh, Tokens.barModuleAlpha)
    strokeColor: Colors.outlineVariant
    strokeWidth: Tokens.borderModule
    rimLight: true
    rimOpacity: Tokens.rimOpacityCard
  }

  // Grid with rows/columns forced past the item count acts as a Row or Column without wrapping.
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
              duration: Tokens.durationDragLift
            }
          }

          BarWidgetLoader {
            id: loader
            widgetId: wrapper.modelData.id || ""
            widgetData: wrapper.modelData || ({})
            widgetScreen: sectionRoot.screen
            section: sectionRoot.section
            sectionWidgetIndex: wrapper.index
            vertical: sectionRoot.vertical
            contentVertical: sectionRoot.contentVertical
            // End-cap rule v5 (docs/design-notes.md, "Chamfer inversion accent"): left inverts only the end-cap, right mirrors that.
            // Grouped cells cut the same diagonal as their group, or as the floating pill when there are no group plates.
            invertChamfer: sectionRoot.grouped ? (sectionRoot.section === "left" && !Tokens.barPill) : (sectionRoot.section === "left" && wrapper.index === 0) || (sectionRoot.section === "right" && wrapper.index !== sectionRoot._lastVisibleIndex)
          }

          // Passive, so the widget's own TapHandler still gets the press.
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

          // Only activates once the long press has armed it, so plain clicks pass through untouched.
          DragHandler {
            id: dragHandler
            target: draggableContent
            enabled: sectionRoot.dragState.sourceSection === sectionRoot.section && sectionRoot.dragState.sourceIndex === wrapper.index
            grabPermissions: PointerHandler.CanTakeOverFromItems | PointerHandler.CanTakeOverFromHandlersOfDifferentType
            onActiveChanged: {
              if (!active && sectionRoot.dragState.sourceSection === sectionRoot.section && sectionRoot.dragState.sourceIndex === wrapper.index) {
                // Drag.drop() rebuilds this Repeater and destroys this delegate; read everything from dragState first.
                var st = sectionRoot.dragState;
                var droppedOnValidTarget = st.targetSection !== "";
                // DragHandler never calls Drag.drop() on release, so do it here or onDropped never fires.
                draggableContent.Drag.drop();
                if (!droppedOnValidTarget) {
                  // Dropped nowhere valid.
                  st.sourceSection = "";
                  st.sourceIndex = -1;
                }
              }
            }
          }
        }
      }
    }

    // Always-present trailing drop zone, so a section whose widgets are all hidden can still take a drop.
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

  // Insertion-point indicator between the two widgets the drop lands between.
  Rectangle {
    width: sectionRoot.vertical ? (sectionRow.width > 0 ? sectionRow.width : 24) : 2
    height: sectionRoot.vertical ? 2 : (sectionRow.height > 0 ? sectionRow.height : 24)
    radius: 1
    color: Colors.primary
    visible: sectionRoot.isDropTarget
    x: sectionRoot.vertical ? 0 : sectionRoot.indicatorPos()
    y: sectionRoot.vertical ? sectionRoot.indicatorPos() : 0
    z: 2000

    SequentialAnimation on opacity {
      running: sectionRoot.isDropTarget
      loops: Animation.Infinite
      NumberAnimation {
        to: 1
        duration: Tokens.durationDropPulse
        easing.type: Tokens.easingDropPulse
      }
      NumberAnimation {
        to: 0.4
        duration: Tokens.durationDropPulse
        easing.type: Tokens.easingDropPulse
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
