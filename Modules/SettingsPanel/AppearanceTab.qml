import QtQuick
import QtQuick.Layouts
import qs.Widgets

// Appearance tab: General and Colors subtabs.
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "general"

  property string initialSubTab: ""
  onInitialSubTabChanged: if (initialSubTab !== "")
                             root.subTab = initialSubTab

  NTabBar {
    Layout.fillWidth: true
    model: [
      {
        "id": "general",
        "label": "General"
      },
      {
        "id": "colors",
        "label": "Colors"
      }
    ]
    activeId: root.subTab
    onActivated: id => root.subTab = id
  }

  AppearanceGeneralSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "general"
  }

  AppearanceColorsSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "colors"
  }
}
