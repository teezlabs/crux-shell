pragma Singleton

import QtQuick

// Lightweight transient status-message toasts ("Wallpaper applied", "Theme
// updated") — distinct from Modules/Bar/Extras/NotificationsWindow.qml's
// persistent, urgent, dismissible notification cards (real desktop
// notifications, per-urgency auto-expiry, action buttons, a "clear all"
// footer). A toast is fire-and-forget: one line of text, no actions, no
// dismiss control, no urgency coloring — it fades in, sits briefly, fades
// back out on its own.
//
// Ported down from noctalia-shell's Modules/Toast/{Toast,ToastOverlay,
// ToastScreen}.qml (~683 lines: title+description+icon+type+action-button+
// swipe-to-dismiss+per-screen queueing). Crux keeps only what's actually
// useful here — a single message string, a duration, and a FIFO queue —
// rendered by one global overlay (Modules/OSD/ToastOverlay.qml) instead of
// an instance per screen.
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
