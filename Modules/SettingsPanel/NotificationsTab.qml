import QtQuick
import QtQuick.Layouts

// Top-level "Notifications" settings tab: General/Duration/History as
// subtabs. Exposes what Commons/Notifs.qml and
// Modules/Bar/Extras/NotificationsWindow.qml actually read from
// Settings.data.notifications.* — ported down from noctalia's Notifications
// settings tabs, General/Duration/History prioritized per scope (per-app
// Rules and a Sound tab were cut — see the settings panel report).
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "general"

  SubTabBar {
    Layout.fillWidth: true
    model: [
      {
        "id": "general",
        "label": "General"
      },
      {
        "id": "duration",
        "label": "Duration"
      },
      {
        "id": "history",
        "label": "History"
      }
    ]
    activeId: root.subTab
    onActiveIdChanged: root.subTab = activeId
  }

  NotificationsGeneralSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "general"
  }

  NotificationsDurationSubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "duration"
  }

  NotificationsHistorySubTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "history"
  }
}
