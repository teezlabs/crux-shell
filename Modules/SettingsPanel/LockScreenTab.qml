import QtQuick
import QtQuick.Layouts

// Top-level "Lock Screen" settings tab: Appearance/Behavior/Monitors as
// subtabs, same two-level Tab -> SubTab nav as General/Bar. Exposes what
// Modules/LockScreen/LockScreen.qml actually reads from
// Settings.data.lockScreen.* — see LockScreenAppearanceSubTab.qml /
// LockScreenBehaviorSubTab.qml / LockScreenMonitorsSubTab.qml for the real
// wiring, ported down from noctalia's LockScreen settings tabs.
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "appearance"

  SubTabBar {
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
