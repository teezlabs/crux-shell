pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Spacing/radius/font/animation tokens. Radius tokens multiply by
// Settings.data.theme.radiusRatio, so one slider goes sharp -> rounded.
Singleton {
  id: root

  readonly property real radiusRatio: Settings.data.theme.radiusRatio

  readonly property int radiusXXS: Math.round(2 * radiusRatio)
  readonly property int radiusXS: Math.round(4 * radiusRatio)
  readonly property int radiusS: Math.round(8 * radiusRatio)
  readonly property int radiusM: Math.round(12 * radiusRatio)
  readonly property int radiusL: Math.round(16 * radiusRatio)

  readonly property int marginXXS: 2
  readonly property int marginXS: 4
  readonly property int marginS: 6
  readonly property int marginM: 9
  readonly property int marginL: 13
  readonly property int marginXL: 18

  readonly property real fontScale: Settings.data.ui.fontScale

  readonly property int fontSizeXS: Math.round(10 * fontScale)
  readonly property int fontSizeS: Math.round(11 * fontScale)
  readonly property int fontSizeM: Math.round(12 * fontScale)
  readonly property int fontSizeL: Math.round(14 * fontScale)
  readonly property int fontSizeXL: Math.round(16 * fontScale)

  readonly property int animationFast: 120
  readonly property int animationNormal: 200
  readonly property int animationSlow: 350

  readonly property real barOpacity: Settings.data.theme.barOpacity
}
