import QtQuick
import QtQuick.Layouts

// Top-level Idle tab: Behavior/Custom subtabs. Backend is Commons/Idle.qml
// — native ext-idle-notify-v1 IdleMonitor instances, not hypridle.conf.
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "behavior"

  property string initialSubTab: ""
  onInitialSubTabChanged: if (initialSubTab !== "")
                             root.subTab = initialSubTab

  SubTabBar {
    Layout.fillWidth: true
    model: [
      {
        "id": "behavior",
        "label": "Behavior"
      },
      {
        "id": "custom",
        "label": "Custom"
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
}
