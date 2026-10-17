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

  // Docked bar: space between the modules and the strip's inner edge line.
  readonly property int barJoinGap: spaceSm

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

  // Color transitions. Every surface, label and icon that changes color on
  // hover, on state, or when matugen regenerates the palette eases through
  // it rather than cutting. Deliberately short: this should read as the
  // color settling, not as an animation playing.
  readonly property int durationColor: 180
  readonly property int easingColor: Easing.OutCubic
  // Slower, for a whole-palette change — a retheme is a real event and
  // reads better as a cross-fade than as 180ms of flicker.
  readonly property int durationRetheme: 420

  // Press feedback: the control swells slightly on the way down and
  // settles back more slowly, so the release reads as a release.
  readonly property real pressScale: 1.04
  readonly property int durationPressIn: 100
  readonly property int easingPressIn: Easing.OutQuad
  readonly property int durationPressOut: 350
  readonly property int easingPressOut: Easing.OutQuint

  // A brief light wash over a control as it activates, fading to nothing.
  readonly property real flashOpacity: 0.18
  readonly property int durationFlash: 350
  readonly property int easingFlash: Easing.OutExpo

  // A sliding highlight moves its leading edge faster than its trailing
  // edge, so it stretches in the direction of travel and snaps back to
  // shape on arrival. Used by the tab bars and the workspace marker.
  readonly property int durationHighlightLead: 200
  readonly property int durationHighlightTrail: 350
  readonly property int easingHighlight: Easing.OutExpo

  // §8 Elevation. Shadows are cast by the surface's own chamfered shape,
  // never a rectangle behind it, so a cut corner still reads as cut in the
  // shadow. Three tiers only: the shell is flat by design and depth is
  // meant to say "this floats above that", not to decorate.
  //
  // Colour is a hard black rather than a tinted one. On the dark themes
  // crux actually runs, a tinted shadow over a near-black desktop reads as
  // a glow, not a shadow.
  readonly property color shadowColor: "#000000"

  // Panels and popups: the launcher, settings, slide cards, the Control
  // Center. These float clear of everything.
  readonly property real shadowBlurPanel: 64
  readonly property real shadowOpacityPanel: 0.8
  readonly property real shadowOffsetPanel: 10

  // Cards inside a panel, and notification toasts: lifted off their own
  // background, not off the desktop, so much tighter.
  readonly property real shadowBlurCard: 28
  readonly property real shadowOpacityCard: 0.55
  readonly property real shadowOffsetCard: 5

  // Bar modules and tiles: barely there. Enough to separate the module
  // from the wallpaper without turning the bar into a row of buttons.
  readonly property real shadowBlurModule: 12
  readonly property real shadowOpacityModule: 0.22
  readonly property real shadowOffsetModule: 2

  // A lit top edge. On the dark themes crux runs, a black shadow over a
  // near-black desktop moves the luminance by about three levels out of
  // 255 — measurably there, visually nothing. A one-pixel highlight along
  // the top edge is what actually makes a surface read as lifted, because
  // it implies a light source above rather than relying on the background
  // having somewhere darker to go.
  readonly property real rimOpacityPanel: 0.30
  readonly property real rimOpacityCard: 0.22

  // §6.1 Bar geometry
  readonly property int barHeight: 42
  readonly property int barModuleHeight: 30
  readonly property int barModuleSpacing: 6
  readonly property int barSidePadding: 10
}
