pragma Singleton

import QtQuick

// Fire-and-forget one-line status toasts, rendered FIFO by Modules/OSD/ToastOverlay.qml.
QtObject {
  id: root

  // ToastOverlay is the only listener, so callers don't need to import qs.Modules.OSD.
  signal requested(string message, int durationMs)

  // Defaults to 2.5s, shorter than the OSD or a notification.
  function show(message, durationMs) {
    if (!message)
      return;
    root.requested(message, durationMs || 2500);
  }
}
