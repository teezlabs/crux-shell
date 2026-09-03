pragma Singleton

import QtQuick
import qs.Commons

// Design tokens: type scale, chamfer sizes, meter geometry, panel opacity/
// blur, motion durations/easings. font.letterSpacing is absolute px in Qt,
// not em — *Tracking values are em fractions, multiply by the matching
// *Size at the call site.
QtObject {
  id: root

  readonly property string fontFamily: Settings.isLoaded ? Settings.data.ui.fontFamily : "JetBrains Mono"
  readonly property string monoFontFamily: Settings.isLoaded ? Settings.data.ui.monoFontFamily : "JetBrains Mono"

  // Every *Size token below is multiplied by this, so the General ->
  // Basics font-scale slider moves the whole type scale at once.
  readonly property real fontScale: Settings.isLoaded ? Settings.data.ui.fontScale : 1.0

  // §2 Type — weight is the lighter of any spec pair; call sites bump to
  // the heavier variant themselves (e.g. font.weight: Font.DemiBold) for
  // selected/active states.
  readonly property int displaySize: Math.round(132 * fontScale)
  readonly property int displayWeight: Font.ExtraLight // 200
  readonly property real displayTracking: -0.04

  readonly property int titleSize: Math.round(30 * fontScale)
  readonly property int titleWeight: Font.Light // 300
  readonly property real titleTracking: -0.02

  readonly property int bodyLgSize: Math.round(15 * fontScale)
  readonly property int bodyLgWeight: Font.Normal // 400 (600 at call sites that need it)
  readonly property real bodyLgTracking: 0

  readonly property int bodySize: Math.round(13 * fontScale)
  readonly property int bodyWeight: Font.Normal // 400 (500 at call sites that need it)
  readonly property real bodyTracking: 0

  readonly property int bodySmSize: Math.round(12 * fontScale)
  readonly property int bodySmWeight: Font.Normal // 400 (600 at call sites that need it)
  readonly property real bodySmTracking: 0

  readonly property int captionSize: Math.round(11 * fontScale)
  readonly property int captionWeight: Font.Normal // 400 (500 at call sites that need it)
  readonly property real captionTracking: 0.08 // spec range 0.05-0.12em

  readonly property int labelSize: Math.round(10 * fontScale)
  readonly property int labelWeight: Font.Medium // 500 (600 at call sites that need it)
  readonly property real labelTracking: 0.16 // spec range 0.14-0.18em

  readonly property int labelXsSize: Math.round(9 * fontScale)
  readonly property int labelXsWeight: Font.DemiBold // 600
  readonly property real labelXsTracking: 0.17 // spec range 0.16-0.18em

  // §4 Geometry — chamfer sizes, one per tier.
  readonly property int chamferPanel: 14 // launcher, control center, sidebar, media, calendar
  readonly property int chamferModule: 9 // bar module, OSD, power tile (spec range 8-10)
  readonly property int chamferIcon: 5 // icon / small tile

  // Corner radius for the few surfaces that are rounded rather than
  // chamfered (the polkit dialog) — crux's own language is chamfers.
  readonly property int radiusXXS: 2

  // §4 Borders
  readonly property int borderPanel: 1
  readonly property int borderModule: 1
  readonly property int borderDivider: 1
  readonly property int borderMarker: 2 // urgency/selection left-edge or bottom-edge marker
  readonly property real destructiveBorderAlpha: 0.25 // "Destructive panel/tile: 1px derived from error @ ~25%"

  // §1 Panel opacity / blur
  readonly property real panelOpacity: 0.95
  readonly property real barModuleOpacity: 0.88
  readonly property int blurBar: 16
  readonly property int blurOsd: 20
  readonly property int blurNotifications: 16

  // §5 Segmented meters — {cells, cellHeight} per context.
  readonly property int meterOsdCells: 20
  readonly property int meterOsdCellHeight: 10
  readonly property int meterControlCenterCells: 16
  readonly property int meterControlCenterCellHeight: 9
  readonly property int meterTelemetryCells: 18
  readonly property int meterTelemetryCellHeight: 5
  readonly property int meterMediaSeekCells: 20
  readonly property int meterMediaSeekCellHeight: 5
  readonly property int meterSidebarSeekCells: 12
  readonly property int meterSidebarSeekCellHeight: 4
  readonly property int meterBarBatteryCells: 5
  readonly property int meterBarBatteryCellHeight: 9
  readonly property int meterCellSpacing: 2

  // §7 Motion
  readonly property int durationPanel: 140
  readonly property int easingPanel: Easing.OutCubic
  readonly property int durationOsdFade: 150
  readonly property int easingOsdFade: Easing.OutQuad
  readonly property int durationNotifEnter: 180
  readonly property int easingNotifEnter: Easing.OutCubic
  readonly property int durationNotifExit: 120
  readonly property int easingNotifExit: Easing.InQuad
  readonly property int durationMeterFill: 90
  readonly property int easingMeterFill: Easing.Linear
  readonly property int durationWorkspaceMarker: 110
  readonly property int easingWorkspaceMarker: Easing.OutCubic
  readonly property int durationBarFade: 200
  readonly property int durationSidebarSlide: 200
  readonly property int easingSidebarSlide: Easing.OutCubic

  // §6.1 Bar geometry
  readonly property int barHeight: 42
  readonly property int barModuleHeight: 30
  readonly property int barModuleSpacing: 6
  readonly property int barSidePadding: 10
}
