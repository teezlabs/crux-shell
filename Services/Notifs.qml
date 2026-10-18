pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.Commons

// The org.freedesktop.Notifications daemon.
Singleton {
  id: root

  readonly property var notifications: server.trackedNotifications ? server.trackedNotifications.values : []

  function clearAll() {
    var list = notifications.slice();
    for (var i = 0; i < list.length; i++)
      list[i].dismiss();
  }

  // Session-only history, capped at maxHistory: trackedNotifications is a live view, so each arrival is snapshotted.
  readonly property int maxHistory: Settings.data.notifications.historyLimit
  property var history: []
  property int _nextHistoryId: 1

  function clearHistory() {
    history = [];
  }

  function removeFromHistory(id) {
    history = history.filter(function (item) {
      return item.id !== id;
    });
  }

  NotificationServer {
    id: server
    keepOnReload: true
    persistenceSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    actionsSupported: true
    imageSupported: true

    onNotification: notification => {
      notification.tracked = true;

      var entry = {
        "id": root._nextHistoryId++,
        "appName": notification.appName || "",
        "summary": notification.summary || "",
        "body": notification.body || "",
        "urgency": notification.urgency,
        "timestamp": Date.now()
      };
      var next = root.history.slice();
      next.unshift(entry);
      if (next.length > root.maxHistory)
        next.length = root.maxHistory;
      root.history = next;
    }
  }
}
