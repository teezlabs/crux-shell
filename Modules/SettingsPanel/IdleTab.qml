import QtQuick
import QtQuick.Layouts
import qs.Widgets
import qs.Services

// Top-level Power tab: idle Behavior/Custom and the Session Menu as subtabs.
// Idle backend is Commons/Idle.qml (ext-idle-notify-v1), not hypridle.conf.
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "behavior"

  property string initialSubTab: ""
  onInitialSubTabChanged: if (initialSubTab !== "")
                             root.subTab = initialSubTab

  NTabBar {
    Layout.fillWidth: true
    model: [
      {
        "id": "behavior",
        "label": "Behavior"
      },
      {
        "id": "custom",
        "label": "Custom"
      },
      {
        "id": "sessionMenu",
        "label": "Session Menu"
      }
    ]
    activeId: root.subTab
    onActiveIdChanged: root.subTab = activeId
  }

  IdleBehaviorSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "behavior"
  }

  IdleCustomSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "custom"
  }

  SessionMenuTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "sessionMenu"
  }
}
