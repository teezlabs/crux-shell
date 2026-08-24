import QtQuick
import qs.Commons
import qs.Modules.Bar.Extras

// One bar section (left/center/right): lays out its widgets in a Row and
// supports long-press-then-drag reordering. Long-press is detected by a
// non-exclusive TapHandler (a passive grab — it does not block the widget's
// own MouseArea underneath, so a plain click keeps working untouched); once
// armed, an enabled DragHandler takes over the same in-progress press to
// move the widget, following the same pattern Qt Quick uses to let a
// Flickable steal a gesture from a child MouseArea mid-press.
Row {
  id: sectionRow

  property string section: ""
  property var screen: null
  readonly property string screenName: screen ? screen.name : ""
  property var widgetsModel: []

  spacing: 6

  property int dragSourceIndex: -1
  property int dragTargetIndex: -1

  Repeater {
    model: sectionRow.widgetsModel

    delegate: Item {
      id: wrapper
      required property var modelData
      required property int index

      readonly property bool isDragged: sectionRow.dragSourceIndex === index
      property real shiftOffset: 0

      width: loader.implicitWidth
      height: loader.implicitHeight

      Binding on shiftOffset {
        value: {
          if (sectionRow.dragSourceIndex === -1 || sectionRow.dragTargetIndex === -1 || wrapper.isDragged)
            return 0;
          var src = sectionRow.dragSourceIndex;
          var tgt = sectionRow.dragTargetIndex;
          if (src < tgt) {
            if (wrapper.index > src && wrapper.index <= tgt)
              return -1 * (wrapper.width + sectionRow.spacing);
          } else if (src > tgt) {
            if (wrapper.index >= tgt && wrapper.index < src)
              return wrapper.width + sectionRow.spacing;
          }
          return 0;
        }
      }

      DropArea {
        anchors.fill: parent
        keys: ["crux-bar-widget-" + sectionRow.section]
        onEntered: function (drag) {
          if (drag.source && drag.source.objectName === "cruxBarWidgetDrag")
            sectionRow.dragTargetIndex = wrapper.index;
        }
        onExited: {
          if (sectionRow.dragTargetIndex === wrapper.index)
            sectionRow.dragTargetIndex = -1;
        }
        onDropped: function (drop) {
          var from = sectionRow.dragSourceIndex;
          var to = wrapper.index;
          sectionRow.dragSourceIndex = -1;
          sectionRow.dragTargetIndex = -1;
          if (drop.source && drop.source.objectName === "cruxBarWidgetDrag" && from !== -1 && from !== to) {
            Settings.reorderBarWidget(sectionRow.screenName, sectionRow.section, from, to);
          }
        }
      }

      Item {
        id: draggableContent
        objectName: "cruxBarWidgetDrag"
        width: parent.width
        height: parent.height
        anchors.centerIn: dragHandler.active ? undefined : parent

        transform: Translate {
          x: dragHandler.active ? 0 : wrapper.shiftOffset
          Behavior on x {
            NumberAnimation {
              duration: 120
              easing.type: Easing.OutQuad
            }
          }
        }

        Drag.active: dragHandler.active
        Drag.source: draggableContent
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2
        Drag.keys: ["crux-bar-widget-" + sectionRow.section]

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
          widgetScreen: sectionRow.screen
          section: sectionRow.section
          sectionWidgetIndex: wrapper.index
        }

        // Non-exclusive: a passive grab that watches for a long press without
        // blocking the widget's own MouseArea from receiving the same press.
        TapHandler {
          id: tapHandler
          acceptedButtons: Qt.LeftButton
          gesturePolicy: TapHandler.DragThreshold
          grabPermissions: PointerHandler.CanTakeOverFromItems | PointerHandler.CanTakeOverFromHandlersOfDifferentType
          onLongPressed: {
            sectionRow.dragSourceIndex = wrapper.index;
          }
        }

        // Only takes over the in-progress press once armed by the long
        // press above — a plain click never reaches drag distance/duration,
        // so this handler never activates and never touches the event.
        DragHandler {
          id: dragHandler
          target: draggableContent
          enabled: sectionRow.dragSourceIndex === wrapper.index
          grabPermissions: PointerHandler.CanTakeOverFromItems | PointerHandler.CanTakeOverFromHandlersOfDifferentType
          onActiveChanged: {
            if (!active && sectionRow.dragSourceIndex === wrapper.index) {
              // DragHandler only toggles Drag.active — nothing calls
              // Drag.drop() on release the way MouseArea.onReleased did in
              // the Taskbar.qml pattern this was adapted from. Do it here,
              // or the DropArea underneath never fires onDropped at all.
              draggableContent.Drag.drop();
              if (sectionRow.dragTargetIndex === -1) {
                // Dropped nowhere valid — reset.
                sectionRow.dragSourceIndex = -1;
              }
            }
          }
        }
      }
    }
  }
}
