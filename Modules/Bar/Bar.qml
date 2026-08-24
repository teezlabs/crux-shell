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

  Row {
    id: leftRow
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: 8
    spacing: 6

    Repeater {
      model: root.barWidgets.left
      delegate: BarWidgetLoader {
        required property var modelData
        required property int index
        widgetId: modelData.id || ""
        widgetScreen: root.screen
        section: "left"
        sectionWidgetIndex: index
      }
    }
  }

  Row {
    anchors.centerIn: parent
    spacing: 6

    Repeater {
      model: root.barWidgets.center
      delegate: BarWidgetLoader {
        required property var modelData
        required property int index
        widgetId: modelData.id || ""
        widgetScreen: root.screen
        section: "center"
        sectionWidgetIndex: index
      }
    }
  }

  Row {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.rightMargin: 8
    spacing: 6

    Repeater {
      model: root.barWidgets.right
      delegate: BarWidgetLoader {
        required property var modelData
        required property int index
        widgetId: modelData.id || ""
        widgetScreen: root.screen
        section: "right"
        sectionWidgetIndex: index
      }
    }
  }
}
