import QtQuick
import QtQuick.Layouts

// Top-level Plugins tab: Installed/Available/Sources subtabs.
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "installed"

  property string initialSubTab: ""
  onInitialSubTabChanged: if (initialSubTab !== "")
                             root.subTab = initialSubTab

  SubTabBar {
    Layout.fillWidth: true
    model: [
      {
        "id": "installed",
        "label": "Installed"
      },
      {
        "id": "available",
        "label": "Available"
      },
      {
        "id": "sources",
        "label": "Sources"
      }
    ]
    activeId: root.subTab
    onActiveIdChanged: root.subTab = activeId
  }

  PluginsInstalledSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "installed"
  }

  PluginsAvailableSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "available"
  }

  PluginsSourcesSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "sources"
  }
}
