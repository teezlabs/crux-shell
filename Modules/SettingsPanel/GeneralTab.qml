import QtQuick
import QtQuick.Layouts
import qs.Widgets

// Input tab: General and Keybinds subtabs.
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "basics"

  // Set by a search jump and applied on change, so the tab bar still drives subTab afterwards.
  property string initialSubTab: ""
  onInitialSubTabChanged: if (initialSubTab !== "")
                             root.subTab = initialSubTab

  NTabBar {
    Layout.fillWidth: true
    model: [
      {
        "id": "basics",
        "label": "General"
      },
      {
        "id": "keybinds",
        "label": "Keybinds"
      }
    ]
    activeId: root.subTab
    onActivated: id => root.subTab = id
  }

  GeneralBasicsSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "basics"
  }

  GeneralKeybindsSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "keybinds"
  }
}
