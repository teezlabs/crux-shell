pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.Commons

// Real org.freedesktop.Notifications DBus daemon — crux's first (Roadmap.md
// flagged this as the biggest single gap). Registers unconditionally; on
// this dev box the DBus name is currently held by the still-running
// noctalia-shell (see crux skill's "Open work"), so actual delivery can't
// be end-to-end verified until crux is the daily driver — but the service
// itself, the tracked-notification list, and the popover UI are all real,
// not stubbed, and will start receiving real notifications the moment
// nothing else owns that name.
Singleton {
  id: root

  readonly property var notifications: server.trackedNotifications ? server.trackedNotifications.values : []

  function clearAll() {
    var list = notifications.slice();
    for (var i = 0; i < list.length; i++)
      list[i].dismiss();
  }

  // Persistent history (backs NotificationHistoryWindow.qml): a notification
  // vanishes from `notifications` above the instant it's dismissed or expires
  // — Quickshell's trackedNotifications is a live view only, never a log.
  // This is the one place that survives dismissal: a plain data snapshot
  // (appName/summary/body/urgency/timestamp) taken the instant each REAL
  // notification arrives via the DBus server below, capped at maxHistory
  // (oldest dropped first). Session-only, not written to disk — matches how
  // the rest of crux's popups hold no state across restarts yet.
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
