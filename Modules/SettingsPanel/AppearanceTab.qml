import QtQuick
import QtQuick.Layouts
import qs.Widgets

// Top-level "Appearance" settings tab: General (font/radius/opacity) and
// Colors (the theme token grid) as subtabs.
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
    onActiveIdChanged: root.subTab = activeId
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
