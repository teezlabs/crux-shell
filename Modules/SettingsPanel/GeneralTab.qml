import QtQuick
import QtQuick.Layouts
import qs.Widgets

// Top-level "Input" settings tab: General (region, input) and Keybinds
// (read-only reference) as subtabs.
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "basics"

  // Set by SettingsWindow's search jump — reacting to onChanged (not a
  // binding) means the NTabBar's own onActivated can still drive
  // subTab normally afterward, instead of a one-way lock to the search hit.
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
