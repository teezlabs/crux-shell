import QtQuick
import QtQuick.Layouts

// Top-level "General" settings tab: Basics (shell info, restart) and
// Keybinds (read-only reference) as subtabs.
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "basics"

  // Set by SettingsWindow's search jump — reacting to onChanged (not a
  // binding) means the SubTabBar's own onActiveIdChanged can still drive
  // subTab normally afterward, instead of a one-way lock to the search hit.
  property string initialSubTab: ""
  onInitialSubTabChanged: if (initialSubTab !== "")
                             root.subTab = initialSubTab

  SubTabBar {
    Layout.fillWidth: true
    model: [
      {
        "id": "basics",
        "label": "Basics"
      },
      {
        "id": "keybinds",
        "label": "Keybinds"
      }
    ]
    activeId: root.subTab
    onActiveIdChanged: root.subTab = activeId
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
