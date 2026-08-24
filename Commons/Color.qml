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

  // Convenience: color + alpha, for hover fills / scrims.
  function alpha(c, a) {
    return Qt.rgba(c.r, c.g, c.b, a);
  }
}
