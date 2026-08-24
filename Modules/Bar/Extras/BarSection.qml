import QtQuick
import qs.Commons
import qs.Modules.Bar.Extras

// One bar section (left/center/right): lays out its widgets in a Row and
// supports long-press-then-drag reordering, including across sections, with
// a visible insertion-point indicator (a thin bar between widgets) while
// dragging — same idea as the drop indicator in noctalia's
// Widgets/NSectionEditor.qml settings-panel reorder UI.
//
// Long-press is detected by a non-exclusive TapHandler (a passive grab —
// it does not block the widget's own MouseArea underneath, so a plain
// click keeps working untouched); once armed, an enabled DragHandler
// takes over the same in-progress press to move the widget, following the
// same pattern Qt Quick uses to let a Flickable steal a gesture from a
// child MouseArea mid-press.
//
// Cross-section support: `dragState` is a single shared object (created
// once in Bar.qml, passed to all three sections) so a drop in one
// section's DropArea can read which *other* section the drag started in.
// Drag.keys/DropArea.keys use one shared key ("crux-bar-widget") rather
// than a per-section one, so drops are accepted across sections too.
//
// The indicator needs to be positioned freely (not locked into the Row's
// own layout flow), so the root here is a plain Item sizing itself to the
// inner Row, not the Row itself.
Item {
  id: sectionRoot

  property string section: ""
  property var screen: null
  readonly property string screenName: screen ? screen.name : ""
  property var widgetsModel: []
  required property QtObject dragState

  implicitWidth: sectionRow.implicitWidth
  implicitHeight: sectionRow.implicitHeight
  width: implicitWidth
  height: implicitHeight

  readonly property bool isDropTarget: dragState.targetSection === section && dragState.sourceSection !== ""

  function indicatorX() {
    var idx = dragState.targetIndex;
    if (idx <= 0)
      return 0;
    var before = repeater.itemAt(Math.min(idx, repeater.count) - 1);
    if (!before)
      return 0;
    return before.x + before.width + sectionRow.spacing / 2 - 1;
  }

  Row {
    id: sectionRow
    spacing: 6

    Repeater {
      id: repeater
      model: sectionRoot.widgetsModel

      delegate: Item {
        id: wrapper
        required property var modelData
        required property int index

        readonly property bool isDragged: sectionRoot.dragState.sourceSection === sectionRoot.section && sectionRoot.dragState.sourceIndex === index

        width: loader.implicitWidth
        height: loader.implicitHeight
        opacity: isDragged && dragHandler.active ? 0.35 : 1

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
                // DragHandler only toggles Drag.active — nothing calls
                // Drag.drop() on release the way MouseArea.onReleased did
                // in the Taskbar.qml pattern this was adapted from. Do it
                // here, or the DropArea underneath never fires onDropped.
                draggableContent.Drag.drop();
                if (sectionRoot.dragState.targetSection === "") {
                  // Dropped nowhere valid — reset.
                  sectionRoot.dragState.sourceSection = "";
                  sectionRoot.dragState.sourceIndex = -1;
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
      width: Math.max(24, sectionRow.width === 0 ? 40 : 0)
      height: 24

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
    width: 2
    height: sectionRow.height > 0 ? sectionRow.height : 24
    radius: 1
    color: "#89b4fa"
    visible: sectionRoot.isDropTarget
    x: sectionRoot.indicatorX()
    y: 0
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
    if (fromSection !== "" && !(fromSection === toSection && (fromIndex === toIndex || fromIndex === toIndex - 1))) {
      Settings.moveBarWidget(screenName, fromSection, fromIndex, toSection, toIndex);
    }
  }
}
