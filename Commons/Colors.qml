pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Semantic colours from Settings.data.theme, named for the spec's tonal-spot roles (§1).
// *Text roles are the foreground on the matching fill; "onPrimary" would read as a signal handler.
Singleton {
  id: root

  readonly property color surface: Settings.data.theme.surface
  readonly property color surfaceContainerLow: Settings.data.theme.surfaceContainerLow
  readonly property color surfaceContainer: Settings.data.theme.surfaceContainer
  readonly property color surfaceContainerHigh: Settings.data.theme.surfaceContainerHigh
  readonly property color outline: Settings.data.theme.outline
  readonly property color outlineVariant: Settings.data.theme.outlineVariant
  readonly property color primary: Settings.data.theme.primary
  readonly property color primaryContainer: Settings.data.theme.primaryContainer
  readonly property color primaryContainerText: Settings.data.theme.primaryContainerText
  readonly property color tertiary: Settings.data.theme.tertiary
  readonly property color error: Settings.data.theme.errorTone
  readonly property color surfaceText: Settings.data.theme.surfaceText
  readonly property color surfaceTextMuted: Settings.data.theme.surfaceTextMuted
  readonly property color primaryText: Settings.data.theme.primaryText
  readonly property color errorText: Settings.data.theme.errorText

  // Alpha over the surface rather than a pre-blended hex, so it reads right on any background.
  readonly property color labelText: alpha(surfaceTextMuted, 0.55)
  readonly property color disabledText: alpha(surfaceTextMuted, 0.40)

  // Calendar out-of-month days have their own spec hex (§6.7), which works out to ~30% rather than 40%.
  readonly property color calendarOutOfMonth: alpha(surfaceTextMuted, 0.30)

  // Bar strip and attached drawers: tinted toward the accent so grey schemes still carry the hue.
  readonly property color barSurface: mix(surface, primary, 0.08)

  // Convenience: color + alpha, for hover fills / scrims.
  function alpha(c, a) {
    return Qt.rgba(c.r, c.g, c.b, a);
  }

  // Linear blend from a to b by t (0..1).
  function mix(a, b, t) {
    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
  }
}
