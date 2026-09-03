import QtQuick
import QtQuick.Layouts
import qs.Widgets

// Top-level Lock Screen tab: Appearance/Behavior/Monitors subtabs.
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "appearance"

  property string initialSubTab: ""
  onInitialSubTabChanged: if (initialSubTab !== "")
                             root.subTab = initialSubTab

  NTabBar {
    Layout.fillWidth: true
    model: [
      {
        "id": "appearance",
        "label": "Appearance"
      },
      {
        "id": "behavior",
        "label": "Behavior"
      },
      {
        "id": "monitors",
        "label": "Monitors"
      }
    ]
    activeId: root.subTab
    onActiveIdChanged: root.subTab = activeId
  }

  LockScreenAppearanceSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "appearance"
  }

  LockScreenBehaviorSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "behavior"
  }

  LockScreenMonitorsSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "monitors"
  }
}
