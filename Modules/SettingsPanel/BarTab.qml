import QtQuick
import QtQuick.Layouts
import qs.Widgets

// Bar tab: Layout and Widgets subtabs.
ColumnLayout {
  id: root
  property string screenName: ""
  spacing: 14

  property string subTab: "layout"

  property string initialSubTab: ""
  onInitialSubTabChanged: if (initialSubTab !== "")
                             root.subTab = initialSubTab

  NTabBar {
    Layout.fillWidth: true
    model: [
      {
        "id": "layout",
        "label": "Layout"
      },
      {
        "id": "widgets",
        "label": "Widgets"
      }
    ]
    activeId: root.subTab
    onActivated: id => root.subTab = id
  }

  BarLayoutSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "layout"
    screenName: root.screenName
  }

  BarWidgetsSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "widgets"
    screenName: root.screenName
  }
}
