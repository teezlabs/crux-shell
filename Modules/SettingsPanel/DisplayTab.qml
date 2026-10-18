import QtQuick
import QtQuick.Layouts
import qs.Widgets

// Display tab: Brightness and Night Light subtabs.
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "brightness"

  property string initialSubTab: ""
  onInitialSubTabChanged: if (initialSubTab !== "")
                             root.subTab = initialSubTab

  NTabBar {
    Layout.fillWidth: true
    model: [
      {
        "id": "brightness",
        "label": "Brightness"
      },
      {
        "id": "nightLight",
        "label": "Night Light"
      }
    ]
    activeId: root.subTab
    onActivated: id => root.subTab = id
  }

  DisplayBrightnessSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "brightness"
  }

  DisplayNightLightSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "nightLight"
  }
}
