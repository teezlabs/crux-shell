import QtQuick
import QtQuick.Layouts

// Top-level "Bar" settings tab: Layout (position/spacing/monitors) and
// Widgets (per-section add/remove) as subtabs.
ColumnLayout {
  id: root
  property string screenName: ""
  spacing: 14

  property string subTab: "layout"

  property string initialSubTab: ""
  onInitialSubTabChanged: if (initialSubTab !== "")
                             root.subTab = initialSubTab

  SubTabBar {
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
    onActiveIdChanged: root.subTab = activeId
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
