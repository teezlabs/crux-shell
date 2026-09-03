pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Semantic color tokens, sourced live from Settings.data.theme, named per
// the Material-3 tonal-spot roles in the "Quickshell Hyprland Shell v2"
// spec (§1). A *Text role is the readable foreground on the matching fill;
// it can't be named onPrimary/onError because QML reads a leading "on" as
// a signal handler. The Settings.data.theme.* keys keep their older names
// so an existing settings.json still loads.
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
  readonly property color primaryText: Settings.data.theme.mOnPrimary
  readonly property color errorText: Settings.data.theme.mOnError

  // Derived, per spec §1 ("Tertiary/label text" and "Disabled/empty" rows) —
  // alpha-composited rather than a flat pre-blended hex, so it reads
  // correctly against whatever's actually behind it instead of just the one
  // background the spec's reference hex assumed.
  readonly property color labelText: alpha(surfaceTextMuted, 0.55)
  readonly property color disabledText: alpha(surfaceTextMuted, 0.40)

  // §6.7 calendar out-of-month days: spec gives this its own distinct
  // reference hex (#2F383F) rather than reusing the general "disabled"
  // derive above — solving the same alpha-blend-over-surface formula for
  // that specific hex lands at ~30%, not disabledText's 40%.
  readonly property color calendarOutOfMonth: alpha(surfaceTextMuted, 0.30)

  // Convenience: color + alpha, for hover fills / scrims.
  function alpha(c, a) {
    return Qt.rgba(c.r, c.g, c.b, a);
  }
}
