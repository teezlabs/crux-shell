import QtQuick
import QtQuick.Layouts

// Top-level Hooks tab: General/Hooks subtabs. Backend is Commons/Hooks.qml.
ColumnLayout {
  id: root
  spacing: 14

  property var targetScreen: null
  property string subTab: "general"

  property string initialSubTab: ""
  onInitialSubTabChanged: if (initialSubTab !== "")
                             root.subTab = initialSubTab

  SubTabBar {
    Layout.fillWidth: true
    model: [
      {
        "id": "general",
        "label": "General"
      },
      {
        "id": "hooks",
        "label": "Hooks"
      }
    ]
    activeId: root.subTab
    onActiveIdChanged: root.subTab = activeId
  }

  HooksGeneralSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "general"
  }

  HooksListSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "hooks"
    targetScreen: root.targetScreen
  }
}
