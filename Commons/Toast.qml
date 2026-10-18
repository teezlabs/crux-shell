pragma Singleton

import QtQuick

// Lightweight transient status toasts ("Wallpaper applied") — fire-and-
// forget, one line, no actions/dismiss/urgency. Distinct from
// NotificationsWindow.qml's real, dismissible desktop notifications.
// Rendered by one global overlay (OSD/ToastOverlay.qml), FIFO queue.
QtObject {
  id: root

  // Emitted once per show() call. Modules/OSD/ToastOverlay.qml is the
  // sole listener and owns the actual queueing/timing — this singleton is
  // just the call-in point so any file can trigger a toast without
  // importing qs.Modules.OSD itself.
  signal requested(string message, int durationMs)

  // durationMs defaults to ~2.5s, matching the "brief status ping" feel
  // (VolumeOsd/NotificationsWindow use their own longer, per-context
  // durations — a toast is meant to be shorter than either).
  function show(message, durationMs) {
    if (!message)
      return;
    root.requested(message, durationMs || 2500);
  }
}
