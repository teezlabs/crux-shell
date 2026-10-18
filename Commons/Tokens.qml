pragma Singleton

import QtQuick
import qs.Commons

// Design tokens. letterSpacing is absolute px in Qt, so *Tracking (em) is multiplied by the matching *Size.
QtObject {
  id: root

  readonly property string fontFamily: Settings.isLoaded ? Settings.data.ui.fontFamily : "JetBrains Mono"
  readonly property string monoFontFamily: Settings.isLoaded ? Settings.data.ui.monoFontFamily : "JetBrains Mono"

  // Scales every *Size token (General > Basics font scale).
  readonly property real fontScale: Settings.isLoaded ? Settings.data.ui.fontScale : 1.0

  // §2 Type: the lighter weight of each spec pair; call sites bump to DemiBold for active states.
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

  // §3 Spacing — the one scale every gap and inset comes from.
  readonly property int spaceXs: 2
  readonly property int spaceSm: 4
  readonly property int spaceMd: 8
  readonly property int spaceLg: 12
  readonly property int spaceXl: 16

  // Height of one row in a popup list (devices, networks, sinks, clips).
  readonly property int rowHeight: 34

  // §4 Geometry — chamfer sizes, one per tier.
  readonly property int chamferPanel: 14 // launcher, control center, sidebar, media, calendar
  readonly property int chamferModule: 9 // bar module, OSD, power tile (spec range 8-10)
  readonly property int chamferIcon: 5 // icon / small tile
  // A cell inside a bar group: chamferModule less 4px inset x (2 - sqrt 2), so its cut runs parallel to the group's.
  readonly property int chamferGroupedCell: 7

  // Docked bar: space between the modules and the strip's inner edge line.
  readonly property int barJoinGap: spaceSm

  // Bar geometry everything placed against the bar reads, so `floating` is honoured in one place.
  readonly property bool barDocked: Settings.isLoaded && Settings.data.bar.showBackground && !Settings.data.bar.floating
  readonly property int barMargin: Settings.isLoaded && Settings.data.bar.floating ? Settings.data.bar.floatMargin : 0
  readonly property bool barFloating: Settings.isLoaded && Settings.data.bar.floating
  // Floating strip drawn as one outlined pill that drawers join, with no group plates inside.
  readonly property bool barPill: barFloating && Settings.data.bar.showBackground
  // Pill: cell cut 7 plus a 5px side inset x (2 - sqrt 2).
  readonly property int chamferBarFloating: 10
  // Screen edge to the bar's inner edge.
  readonly property int barExtent: (Settings.isLoaded ? Settings.data.bar.thickness : 0) + barMargin + (barDocked ? barJoinGap : 0)

  // Radius for the few rounded surfaces (the polkit dialog); crux otherwise uses chamfers.
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
  // Fill alpha of the bar's module plates and group surfaces, from the user's settings.
  readonly property real barModuleAlpha: Settings.isLoaded ? Settings.data.bar.backgroundOpacity : 1
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
  readonly property int durationCaretBlink: 500
  readonly property int durationDragLift: 120
  readonly property int durationDropPulse: 400
  readonly property int easingDropPulse: Easing.InOutQuad
  readonly property int easingWallpaperTransition: Easing.InOutCubic

  // Colour transitions: short enough to read as the colour settling, not an animation.
  readonly property int durationColor: 180
  readonly property int easingColor: Easing.OutCubic
  // A whole-palette change cross-fades more slowly.
  readonly property int durationRetheme: 420

  // Press: swell on the way down, settle back more slowly so the release reads.
  readonly property real pressScale: 1.04
  readonly property int durationPressIn: 100
  readonly property int easingPressIn: Easing.OutQuad
  readonly property int durationPressOut: 350
  readonly property int easingPressOut: Easing.OutQuint

  // A brief light wash over a control as it activates, fading to nothing.
  readonly property real flashOpacity: 0.18
  readonly property int durationFlash: 350
  readonly property int easingFlash: Easing.OutExpo

  // Sliding highlight: the leading edge outruns the trailing one, stretching toward travel (tab bars, workspaces).
  readonly property int durationHighlightLead: 200
  readonly property int durationHighlightTrail: 350
  readonly property int easingHighlight: Easing.OutExpo

  // §8 Elevation (docs/look-and-feel.md, "Depth"): shadows follow the chamfered shape, three tiers, hard black.
  readonly property color shadowColor: "#000000"

  // Panels and popups, floating clear of everything.
  readonly property real shadowBlurPanel: 64
  readonly property real shadowOpacityPanel: 0.8
  readonly property real shadowOffsetPanel: 10

  // Cards inside a panel and notification toasts.
  readonly property real shadowBlurCard: 28
  readonly property real shadowOpacityCard: 0.55
  readonly property real shadowOffsetCard: 5

  // Bar modules and tiles: barely there.
  readonly property real shadowBlurModule: 12
  readonly property real shadowOpacityModule: 0.22
  readonly property real shadowOffsetModule: 2

  // Rim light: a black shadow barely shows on a near-black desktop, so a lit top edge is what reads as lift.
  readonly property real rimOpacityPanel: 0.30
  readonly property real rimOpacityCard: 0.22

  // §6.1 Bar geometry
  readonly property int barHeight: 42
  // Bar cells keep 5px clear inside the bar's thickness (32 / 30 at the default 42).
  readonly property int barCell: Math.max(20, (Settings.isLoaded ? Settings.data.bar.thickness : 42) - 10)
  readonly property int barModuleHeight: barCell - 2
  readonly property int barModuleSpacing: 6
  readonly property int barSidePadding: 10
}
