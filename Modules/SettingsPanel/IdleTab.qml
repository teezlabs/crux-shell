import QtQuick
import QtQuick.Layouts

// Top-level "Idle" settings tab: Behavior/Custom as subtabs. Real backend
// is Commons/Idle.qml — native ext-idle-notify-v1 IdleMonitor instances
// (Quickshell.Wayland), not a generated hypridle.conf + external process.
// crux had zero idle infrastructure before this; see the settings panel
// report for the full mechanism. Ported down from noctalia's Idle settings
// tabs (BehaviorSubTab/CustomSubTab), trimmed of its fade-overlay UI.
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "behavior"

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
