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

  BarSection {
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: 8
    section: "left"
    screen: root.screen
    widgetsModel: root.barWidgets.left
  }

  BarSection {
    anchors.centerIn: parent
    section: "center"
    screen: root.screen
    widgetsModel: root.barWidgets.center
  }

  BarSection {
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.rightMargin: 8
    section: "right"
    screen: root.screen
    widgetsModel: root.barWidgets.right
  }
}
