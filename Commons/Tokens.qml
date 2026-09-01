pragma Singleton

import QtQuick
import qs.Commons

// Design tokens for the "Quickshell Hyprland Shell v2" spec: type scale,
// chamfer sizes, segmented-meter geometry, panel opacity/blur, and motion
// durations/easings. Every panel built against that spec reads only from
// here for those values — see the spec's §9 hard rule 2 (no hardcoded
// literals) extended to these tokens too.
//
// font.letterSpacing in Qt is absolute pixels, not em — the *Tracking
// properties below are em fractions per the spec's own units; multiply by
// the matching *Size at the call site (font.letterSpacing: Tokens.captionSize
// * Tokens.captionTracking) rather than hardcoding a px value.
QtObject {
  id: root

  // Was hardcoded to "JetBrains Mono" regardless of the General settings
  // tab's own font picker (Settings.data.ui.fontFamily) — since nearly
  // every widget reads Tokens.fontFamily, that setting silently did
  // nothing anywhere. Fallback only covers Settings not being loaded yet.
  readonly property string fontFamily: Settings.isLoaded ? Settings.data.ui.fontFamily : "JetBrains Mono"

  // §2 Type — one representative tracking value picked from each spec
  // range (documented alongside), weight is the *lighter* of any given
  // pair (QML Text has one font.weight; call sites bump to the heavier
  // value themselves — e.g. font.weight: Font.DemiBold — where the spec's
  // "600" variant applies, such as a selected/active state).
  readonly property int displaySize: 132
  readonly property int displayWeight: Font.ExtraLight // 200
  readonly property real displayTracking: -0.04

  readonly property int titleSize: 30
  readonly property int titleWeight: Font.Light // 300
  readonly property real titleTracking: -0.02

  readonly property int bodyLgSize: 15
  readonly property int bodyLgWeight: Font.Normal // 400 (600 at call sites that need it)
  readonly property real bodyLgTracking: 0

  readonly property int bodySize: 13
  readonly property int bodyWeight: Font.Normal // 400 (500 at call sites that need it)
  readonly property real bodyTracking: 0

  readonly property int bodySmSize: 12
  readonly property int bodySmWeight: Font.Normal // 400 (600 at call sites that need it)
  readonly property real bodySmTracking: 0

  readonly property int captionSize: 11
  readonly property int captionWeight: Font.Normal // 400 (500 at call sites that need it)
  readonly property real captionTracking: 0.08 // spec range 0.05-0.12em

  readonly property int labelSize: 10
  readonly property int labelWeight: Font.Medium // 500 (600 at call sites that need it)
  readonly property real labelTracking: 0.16 // spec range 0.14-0.18em

  readonly property int labelXsSize: 9
  readonly property int labelXsWeight: Font.DemiBold // 600
  readonly property real labelXsTracking: 0.17 // spec range 0.16-0.18em

  // §4 Geometry — chamfer sizes, one per tier.
  readonly property int chamferPanel: 14 // launcher, control center, sidebar, media, calendar
  readonly property int chamferModule: 9 // bar module, OSD, power tile (spec range 8-10)
  readonly property int chamferIcon: 5 // icon / small tile

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
  readonly property int durationSidebarSlide: 200
  readonly property int easingSidebarSlide: Easing.OutCubic

  // §6.1 Bar geometry
  readonly property int barHeight: 42
  readonly property int barModuleHeight: 30
  readonly property int barModuleSpacing: 6
  readonly property int barSidePadding: 10
}
