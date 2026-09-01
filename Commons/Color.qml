pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Semantic color tokens, sourced live from Settings.data.theme — this is
// what makes the color scheme actually configurable (settings-panel work),
// rather than every widget hardcoding its own hex strings the way crux did
// up through tonight. Naming convention (mPrimary, mOnPrimary, ...) matches
// noctalia's Commons/Color.qml on purpose — same idea, "m" prefix so QML
// doesn't misread e.g. "onPrimary" as a signal handler name.
Singleton {
  id: root

  readonly property color mPrimary: Settings.data.theme.mPrimary
  readonly property color mOnPrimary: Settings.data.theme.mOnPrimary
  readonly property color mSecondary: Settings.data.theme.mSecondary
  readonly property color mOnSecondary: Settings.data.theme.mOnSecondary
  readonly property color mSurface: Settings.data.theme.mSurface
  readonly property color mOnSurface: Settings.data.theme.mOnSurface
  readonly property color mSurfaceVariant: Settings.data.theme.mSurfaceVariant
  readonly property color mOnSurfaceVariant: Settings.data.theme.mOnSurfaceVariant
  readonly property color mOutline: Settings.data.theme.mOutline
  readonly property color mError: Settings.data.theme.mError
  readonly property color mOnError: Settings.data.theme.mOnError

  // Material-3 tonal-spot roles — the "Quickshell Hyprland Shell v2" spec's
  // own naming (§1). New/rewritten widgets read these directly instead of
  // the m-prefixed roles above.
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
