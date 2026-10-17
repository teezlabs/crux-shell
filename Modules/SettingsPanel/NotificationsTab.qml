import QtQuick
import QtQuick.Layouts
import qs.Widgets

// Top-level Notifications tab: General/Duration/History/OSD subtabs.
ColumnLayout {
  id: root
  spacing: 14

  property string subTab: "general"

  property string initialSubTab: ""
  onInitialSubTabChanged: if (initialSubTab !== "")
                             root.subTab = initialSubTab

  NTabBar {
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
      },
      {
        "id": "osd",
        "label": "OSD"
      }
    ]
    activeId: root.subTab
    onActivated: id => root.subTab = id
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

  OsdTab {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: root.subTab === "osd"
  }
}
