import QtQuick
import QtQuick.Layouts

// Top-level "General" settings tab: Basics (shell info, restart) and
// Keybinds (read-only reference) as subtabs.
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "basics"

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
