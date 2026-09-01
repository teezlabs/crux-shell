import QtQuick
import QtQuick.Layouts

// Top-level "Display" settings tab: Brightness and Night Light as
// subtabs — mirrors noctalia's Display tab, minus the pages crux has
// nothing behind yet (multi-monitor DDC calibration, geolocation).
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "brightness"

  SubTabBar {
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
    onActiveIdChanged: root.subTab = activeId
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
