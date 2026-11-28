pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.Commons

// The org.freedesktop.Notifications daemon. Messages from one app and sender form a conversation (after lyne-dots):
// a new one replaces that conversation's earlier popup, and the history groups them.
Singleton {
  id: root

  readonly property var notifications: server.trackedNotifications ? server.trackedNotifications.values : []

  function clearAll() {
    var list = notifications.slice();
    for (var i = 0; i < list.length; i++)
      list[i].dismiss();
  }

  // App plus summary: chat apps put the sender (or the group) in the summary.
  function conversationKey(n) {
    return (n.appName || "") + "\n" + (n.summary || "");
  }

  // Session-only history, capped at maxHistory: trackedNotifications is a live view, so each arrival is snapshotted.
  readonly property int maxHistory: Settings.data.notifications.historyLimit
  property var history: []
  property int _nextHistoryId: 1

  // Newest first, one entry per conversation: { key, appName, summary, urgency, timestamp, messages: [entry…] }.
  readonly property var conversations: {
    const byKey = {};
    const out = [];
    for (const e of root.history) {
      let c = byKey[e.key];
      if (!c) {
        c = byKey[e.key] = {
          "key": e.key,
          "appName": e.appName,
          "summary": e.summary,
          "urgency": e.urgency,
          "timestamp": e.timestamp,
          "messages": []
        };
        out.push(c);
      }
      c.messages.push(e);
    }
    return out;
  }

  // The last few messages of a conversation, oldest first, for a popup to show above the newest.
  function threadFor(key, limit) {
    const msgs = root.history.filter(e => e.key === key).slice(0, limit || 4);
    return msgs.reverse();
  }

  function clearHistory() {
    history = [];
  }

  function removeFromHistory(id) {
    history = history.filter(function (item) {
      return item.id !== id;
    });
  }

  function removeConversation(key) {
    history = history.filter(item => item.key !== key);
  }

  function _record(entry) {
    var next = root.history.slice();
    next.unshift(entry);
    if (next.length > root.maxHistory)
      next.length = root.maxHistory;
    root.history = next;
  }

  // Sends an inline reply and notes it in the conversation, so the thread shows what you said.
  function reply(notification, text) {
    if (!notification || !notification.hasInlineReply || text.trim() === "")
      return;
    notification.sendInlineReply(text);
    root._record({
      "id": root._nextHistoryId++,
      "key": root.conversationKey(notification),
      "appName": notification.appName || "",
      "summary": notification.summary || "",
      "body": text,
      "own": true,
      "urgency": NotificationUrgency.Low,
      "timestamp": Date.now()
    });
    notification.dismiss();
  }

  NotificationServer {
    id: server
    keepOnReload: true
    persistenceSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    actionsSupported: true
    imageSupported: true
    inlineReplySupported: true

    onNotification: notification => {
      const key = root.conversationKey(notification);
      // One popup per conversation: the newest message takes the earlier one's place.
      for (const other of root.notifications.slice()) {
        if (other !== notification && root.conversationKey(other) === key)
          other.expire();
      }
      notification.tracked = true;

      root._record({
        "id": root._nextHistoryId++,
        "key": key,
        "appName": notification.appName || "",
        "summary": notification.summary || "",
        "body": notification.body || "",
        "own": false,
        "urgency": notification.urgency,
        "timestamp": Date.now()
      });
    }
  }
}
