# Design Notes

Companion to [`qml-gotchas.md`](qml-gotchas.md). Code comments in crux QML files should stay terse
(one line, only when truly non-obvious) — the *why* behind a port decision,
a layout formula, or a bugfix belongs here instead, not as a multi-paragraph
block in the source. Keep entries short and dated-by-topic, not
chronological.

## Always-mapped overlay windows need an explicit input mask

`PopupHost.qml` (one always-mapped `PanelWindow` per screen, replacing
popups each being their own show/hide `PanelWindow`) caused a real,
severe incident the first time it went live: **total input lockup, the
user couldn't click anything on their desktop**, not just near the
popup. Root cause: a mapped layer-shell surface claims pointer/keyboard
input across its *entire* advertised geometry by default — completely
independent of any internal QML `MouseArea`'s own `enabled` binding.
`enabled: false` only stops that Item's *handlers* from firing; it does
nothing to the Wayland surface's actual accepted-input region. A
full-screen surface that stays mapped permanently (the whole point of
this pattern, so a close animation has something to render on) was
therefore swallowing every click on the entire screen the whole time it
was mapped, popup open or not — confirmed by the user being unable to
click anything even with the popup itself fully closed/invisible.

Fix: `PanelWindow.mask` (a `Region`). `mask: null` reverts to the
default (full capture) — used only while something's actually open, to
still catch an outside click and close it. A genuinely empty `Region {}`
(not just one with `width: 0`/`height: 0` — go with the bare/empty form,
same idiom noctalia's own always-mapped overlays use) makes the surface
fully click-through with nothing captured anywhere, used the rest of the
time:

```qml
mask: root.anyOpen ? null : emptyMask
Region { id: emptyMask }
```

**Any future always-mapped full-screen `PanelWindow` in crux needs this
same treatment** — it is not optional, and the failure mode if skipped
is a full desktop lockup, not a cosmetic glitch. A `visible: false`-toggled
popup window never had this problem because unmapping already removes it
from the compositor's input routing entirely; this only bites surfaces
that stay mapped on purpose.

## Slide-to-close animation: collapse size, don't translate off past the bar

The first version of `SlideCard.qml`'s close animation translated the
card's `x`/`y` position off past the corresponding screen edge (matching
the reference shell this was ported from, MystiaFin/shell's `EdgeWidget`).
Looked wrong in practice: `PopupHost` sits on `WlrLayer.Overlay`, above
the bar's own `WlrLayer.Top`, so a card sliding *past* the bar on its way
off-screen always renders on top of it, never behind — it reads as flying
past the bar, not retracting into it (user's exact words: "shouldn't it
technically be going back into the bar?"). Fixed by collapsing the
axis-of-travel dimension (`width` for a left/right bar, `height` for
top/bottom) back to `0` at the bar-facing edge instead of translating
position — the far edge moves, the near edge (touching the bar) stays
pinned, `clip: true` on the wrapper. Reads as being absorbed into the bar
with no layering trick needed, since it's shrinking rather than needing
to actually be spatially behind anything.

## Bar background — opt-in, not a redesign

A continuous solid backdrop behind the whole bar was tried once already
(replacing the detached-floating-modules look entirely) and was explicitly
rejected ("nope i hate it") — fully reverted, back to transparent bar +
edge-glow line only (see shell.qml's own long-standing comment on `barRect`).
When later asked for "a real color behind the modules like noctalia,"
`Settings.data.bar.showBackground` was added as an **opt-in toggle**
(default off, preserving the existing look) rather than repeating that
mistake — same for `floating` (detached-with-gap vs a real edge-to-edge
strip) and `barBackgroundOpacity` (separate from the pre-existing per-
module `useSeparateOpacity`/`backgroundOpacity`, which only ever affected
each module's own individual chamfer fill, not a bar-wide surface). Don't
default either of these on without being asked again.

## Chamfer inversion accent

Two shared chrome components — `BarModule.qml` and `BarIconButton.qml` —
both take an `invertChamfer: bool` prop that mirrors which two opposite
corners get cut (top-left+bottom-right instead of the usual
top-right+bottom-left). This is a deliberate one-off visual accent the user
asked for directly (reference screenshot: power button + VOL tile sitting
next to each other with different chamfer directions and different
heights), not a new global convention — most widgets should keep the
standard direction.

Two places use it:
- **`ControlCenter.qml`** (left section): inverts + grows taller than the
  standard 32px square, but only on a horizontal bar (`!root.vertical`).
  The height match isn't a hardcoded guess — it binds its `BarModule`'s
  `vertical` prop to `root.contentVertical` (the same flag `Sound.qml`,
  always compact-safe, receives as its *effective* vertical), and includes
  an invisible `Column` of two `Text` items with Sound's exact font tokens
  purely to force identical `implicitHeight` computation. This makes the
  two tiles pixel-match automatically, including if Sound's stacked
  portrait-compact case ever activates, with no magic number to keep in
  sync.
- **Left/right sections**: left keeps the original "only the end-cap
  inverts" rule (first module, index 0, cut facing outward/left; every
  other left module stays standard). Right is now the *true mirror* of
  left, not an independently-symmetric copy of the same rule: reverse the
  sequence **and** flip every shape to its own mirror-image, so the
  right end-cap (last *visible* module) is the one **non**-inverted
  module and every other right module inverts — the opposite assignment
  from left. Fifth revision of this rule (v1: "everything in right except
  last"; v2: "only the end module, by list index"; v3: "every right
  module"; v4: "only the end module, by last *visible* index, standard
  everywhere else"; v5, current: "left unchanged from v4; right is v4's
  exact opposite — end-cap standard, everything else inverted") — don't
  resurrect v1–v4's right-side rule. v5 landed after actually trying v4
  live and confirming it looked wrong to the user; the reasoning that got
  there: two shapes that are literal mirror-images of each other
  (cutTopLeft+cutBottomRight vs cutTopRight+cutBottomLeft) only produce a
  *real* mirror across the two sections if you swap which shape each role
  gets, not just keep the same rule twice — reversing the visual order
  alone isn't enough when the shapes themselves are chiral.
  Computed once in `BarSection.qml` (`_lastVisibleIndex`, reusing the same
  `repeater.itemAt(i)`/`_sizeVersion` pattern the section's own implicit-
  size calc already uses) and forwarded through `BarWidgetLoader.qml` the
  same way `vertical`/`contentVertical` already are.
  **Real bug hit on v2/v3**: using the last *list* index instead of last
  *visible* index meant a trailing widget hidden by its own logic (Updates
  at 0 count with `hideOnZero`) silently "stole" the accent — Sound (the
  actual rightmost thing rendered) looked unstyled while an invisible
  widget past it was the one actually inverted. Always resolve "the end
  module" against what's rendered, not the raw widgets list.

Threaded through: `Media.qml`, `Tray.qml`, `Settings.qml` (gear),
`PowerButton.qml` (raw `Chamfer`, not the shared components — wired
directly), `Sound.qml`, and the `Updates` local plugin's `Widget.qml`. Any
other built-in dragged into the right section won't have the accent until
wired the same way (one `property bool invertChamfer: false` + a pass-
through into its `BarModule`/`BarIconButton`/`Chamfer`).

## Wallpaper switch shader transitions (ported from noctalia)

`Background.qml` ports noctalia-shell's `Modules/Background/Background.qml`
shader-transition system (fade/wipe/disc/stripes/pixelate/honeycomb) —
copied the **compiled** `.qsb` bytecode verbatim into `Assets/Shaders/`
rather than recompiling from `.frag` source, since they're portable RHI
bytecode with zero crux-specific logic. Deliberately dropped from
noctalia's original: solid-color wallpaper mode, compositor-scale-aware
image caching service, fill-mode picker (crux only ever uses
`PreserveAspectCrop`, so those shader uniforms get fixed constants instead
of a real settings-backed picker).

**Real bug hit during the port**: a naive `if (!root.initialized) return;`
guard in `onTargetUrlChanged` created a chicken-and-egg deadlock —
`initialized` only ever flips true from a successful image load, but the
only place that kicked off a load was `Component.onCompleted`, which can
fire before `Settings.data.wallpaper.path` has finished its own async
load (empty string). Result: wallpaper never renders at all (confirmed via
screenshot — solid black desktop), and it's *permanent*, not just a boot
race, since every subsequent real path change gets silently dropped by the
same guard. Fix: the "not yet initialized" branch must still assign
`currentWallpaper.source = targetUrl` (not just bail), so whichever change
event happens to carry the first real path — `onCompleted` or a later
`onTargetUrlChanged` — is the one that unblocks `initialized`.

Settings added: `Settings.data.wallpaper.transitionType` (`list<string>`,
default `["fade"]` — more than one means pick randomly per switch, same as
noctalia), `transitionDuration` (ms), `transitionEdgeSmoothness` (wipe/
disc/stripes edge softness).

## Bar widget drag-reorder: TapHandler vs MouseArea gotcha

`BarSection.qml`'s long-press-then-drag reordering uses a non-exclusive
(passive) `TapHandler` on each widget wrapper to detect the long-press,
without blocking the widget's own click handling underneath. This only
works if every bar widget's own click handling is *also* a pointer
handler (`TapHandler`/`HoverHandler`), not a legacy `MouseArea` — on this
box's Qt 6.11, a passive ancestor `TapHandler` never receives ANY event
(not even a plain press) when a legacy `MouseArea` sits underneath it,
contrary to the usual "Flickable steals from MouseArea" folklore. Every
`Modules/Bar/Widgets/*.qml` file's own click handling was converted from
`MouseArea` to `TapHandler`+`HoverHandler` for this reason — reintroducing
a `MouseArea` in a bar widget silently breaks its drag reordering, with no
error, just a widget that stops being draggable.

Cross-section dragging works because `dragState` is a single shared object
(created once in `Bar.qml`, passed to all three sections) so a drop in one
section's `DropArea` can read which *other* section the drag started in —
`Drag.keys`/`DropArea.keys` use one shared key (`"crux-bar-widget"`)
rather than a per-section one, so drops are accepted across sections too.

Two traps in the release handler. `DragHandler` only toggles `Drag.active`; unlike `MouseArea.onReleased` in the Taskbar pattern this was adapted from, nothing calls `Drag.drop()`, so the handler has to, or the `DropArea` never fires `onDropped`. And `Drag.drop()` commits the move synchronously through `Settings.moveBarWidget`, which rebuilds the section's `Repeater` and destroys the very delegate running the handler. Anything needed afterwards is read from `dragState` (owned by `Bar.qml`) before the call.

## Desktop widgets: fixed two-card port, not noctalia's full system

`DesktopWidgets.qml` is a deliberately trimmed port of noctalia's
DesktopWidgets — two fixed cards (weather, media), draggable and
individually toggleable, positions persisted to
`Settings.data.desktopWidgets.weatherX/Y|mediaX/Y` (-1 sentinel = "never
moved, use the default bar-aware corner"). Not ported: noctalia's full
drag-to-reposition/edit-mode system (`DraggableDesktopWidget.qml`,
grid-snap overlay, add-widget popup) — just enough to move/hide these two
cards. Sits on `WlrLayer.Bottom` (above the wallpaper's `WlrLayer.
Background`, below real app windows), `ExclusionMode.Ignore`, with an
explicit `Region` mask so only the two card rectangles are hit-testable —
everything else passes mouse input through to whatever's behind it.
Reuses `Commons/Weather.qml` (same ip-api.com/open-meteo.com data already
fetched for the Control Center card) and the same MPRIS pattern
`MediaPlayerWindow.qml`/`ControlCenterWindow.qml` use, rather than
standing up new data sources.

## `Quickshell.screens[0]` doesn't reliably invalidate bindings

A per-screen-singleton pattern (e.g. `NightLight.qml`'s "only the instance
on `Quickshell.screens[0]` actually manages the `wlsunset` process")
cannot rely on a live computed binding like `readonly property bool:
root.screen === Quickshell.screens[0]`. Confirmed via direct debug
logging: a binding reading through `Quickshell.screens[0]` (array-index
access) does not reliably re-evaluate when `screen` arrives — same class
of bug as the Grid/`itemAt()` dependency-tracking gotcha ("reads mediated
through a function call aren't tracked reliably; reading your own
property directly is always picked up"). Comparing by object identity
(`===`) doesn't fix it either — on real multi-monitor hardware, both
instances printed `primary=false` against `Quickshell.screens[0]`, even
though the two are supposed to be the same `QuickshellScreenInfo`.

Fix: compute it *imperatively* into a plain stored property at the exact
points that matter (`onScreenChanged`, `Component.onCompleted`), instead
of trusting either binding form to invalidate itself. This same
`===`-against-`screens[0]` pattern is used elsewhere for per-screen
`IpcHandler` gates (`PopupIpc.qml` derives the per-screen target name the
same way) — worth re-checking those the same way if a multi-monitor bug ever
shows up there.

## Scroll Lock indicator always reads "unknown", not a bug

`LockKeys.qml`: `hyprctl devices -j` reports `capsLock`/`numLock` per
keyboard directly, but scroll lock isn't in that JSON at all, and this
hardware has no `/sys/class/leds/*::scrolllock` LED to fall back to either
(checked directly — no lock LEDs exist in sysfs on this box). So its
indicator always shows dim/"unknown" rather than lying about the state.
Don't chase this as a bug — it's a real hardware/protocol limitation,
already handled deliberately.

## Portrait-monitor bar: contentVertical vs. barIsVertical

`shell.qml`'s per-screen bar `PanelWindow` distinguishes two different
things that are easy to conflate:

- `barIsVertical` — the bar's *configured position* is left/right (a real
  vertical bar).
- `screenIsPortrait` — the *screen* is taller than wide (e.g. this box's
  DP-1, a physically rotated monitor), even when the bar position is
  "top"/"bottom" — the bar is still a physically horizontal strip, just
  spanning the screen's short edge with much less room than a normal
  landscape top bar.
- `contentVertical = barIsVertical || screenIsPortrait` — widget-internal
  content (Clock's date+time, StatusGroup's NET/VOL pairs) should use the
  same compact/stacked style either way, since both cases are cramped.

**Not blanket-applied to every widget** — confirmed real breakage doing
that: Tray's and Workspaces' own `vertical` prop means "stack items along
the bar's long axis," which only has room on a real vertical (left/right)
bar. Forcing it on for a horizontal top bar just because the screen is
portrait made Tray's icons stack downward past the bar's own height with
nothing bounding them. Only widgets confirmed to fit a modest thickness
bump (short text stacks, not multi-item grids) opt in — see
`BarWidgetLoader.qml`'s `_compactSafeIds`.

**Update, later session:** the `compactOnHorizontalBar` 56px floor
described below was removed from `shell.qml`. It existed because
`ControlCenter`/`Sound` used to read the broad `contentVertical` flag
(vertical bar OR portrait screen) to grow taller and match `Sound`'s
stacked height — which overflowed a thinner bar on DP-1 specifically.
Real bug, confirmed by pixel-measuring the rendered tiles: they were
~7-9px taller than every other module. Fixed at the source instead of
the symptom: `ControlCenter` no longer reads that broad flag for height
at all (pinned to standard `Tokens.barModuleHeight`), and `Sound` was
removed from `BarWidgetLoader.qml`'s `_compactSafeIds` (it only makes
sense to stack-and-grow on a *real* vertical bar, where height is the
long axis with room to spare — not a horizontal bar whose thickness
setting **is** the cross-axis, portrait screen or not). With both
sources of overflow gone, the floor was dead weight — the Settings
thickness slider now applies as configured on every screen, no silent
minimum floor. Original reasoning for the floor kept below for context:

`compactOnHorizontalBar = contentVertical && !barIsVertical` bumps
`effectiveThickness` (min 56px) specifically for the portrait-screen +
horizontal-bar case — a true vertical bar already has room along its own
long axis, but a top/bottom bar's cross-axis *is* its thickness setting,
which doesn't grow on its own just because the content inside got taller.
Confirmed via screenshot: without this, Clock's stacked HH/mm/date
visibly overflowed past the bottom of its own chamfered module.

Separately: auto-hide fades the bar out until the pointer reaches its
screen edge, but the `PanelWindow` itself always stays mapped — full
opacity 0 doesn't remove a wlr-layer-shell surface from the compositor,
those aren't reactive to CSS-style `display:none` — so hover detection
still works while the bar is visually hidden.

## TextInput.cursorVisible: false doesn't actually suppress the native cursor

`LauncherWindow.qml`'s search box draws its own spec-mandated blinking
caret (a plain `Rectangle`, 2px×17px, `Colors.primary`) instead of using
`TextInput`'s built-in one. Setting `cursorVisible: false` on the
`TextInput` looked like the obvious way to stop it from *also* drawing its
own default cursor on top — it's the documented property for exactly this
— but confirmed live on two separate machines that it does **not**
actually suppress it: a second, white, native cursor kept blinking
alongside the real caret regardless. The real fix is overriding
`cursorDelegate: Item {}` — an empty delegate forces `TextInput` to
instantiate nothing for its cursor visual instead of merely hiding it.

This one was hard to pin down because the native cursor turned out to be
**invisible to every screenshot tool tried** (`grim`, the user's own
`rishot`) on both machines, which sent troubleshooting down several wrong
paths before landing on the real cause (mouse pointer, monitor rotation,
Nvidia hardware-cursor-plane bugs — all wrong, all confirmed wrong by
direct testing before moving on). The actual reason a screenshot kept
missing it: **it blinks**, same as the real caret, just out of phase —
any single static capture has a real chance of catching it mid-off-phase,
which produced consistently "clean" screenshots even though the bug was
live the whole time. Lesson: a blinking element that "doesn't show up in
a screenshot" is not proof it isn't real QML content — try disabling
candidate elements one at a time and asking for a live (non-screenshot)
confirmation before ruling out the obvious cause.

## Conditional anchors don't reliably re-resolve after Settings loads

The bar's edge-glow border line (`shell.qml`) uses plain `x`/`y`/`width`/
`height` bindings instead of `anchors`, deliberately. Anchors that
conditionally switch a side between a real target and `undefined`
(needed here since which edge the line hugs depends on
`barIsVertical`/`barPosition`) don't reliably re-resolve once
`Settings.isLoaded` flips true: the binding first evaluates while
`Settings.isLoaded` is still false (`barPosition` defaults to
"top"/horizontal for every screen), and a screen whose real configured
position is actually vertical never correctly flipped its anchors over
afterward. Confirmed via a debug `console.log` that fired with
`vertical=false/position=top` on a screen configured as "left" — the
line rendered fine on the "top" screen (no flip ever needed) but never
on the "left" one (needed a flip that never took). Plain property
bindings don't have that staleness — they fully re-evaluate. Same root
cause class as the `Quickshell.screens[0]` binding gotcha above: some
binding forms in this Qt version just don't reliably invalidate on a
later dependency change, even though a fresh evaluation would give the
right answer.

## Settings-panel slider drag needs `preventStealing`

`NSlider.qml`'s drag `MouseArea` sets `preventStealing: true`. Without it,
a drag that isn't perfectly horizontal lets an ancestor `Flickable`
(every settings subtab is one — see the Flickable-overflow-fix pass
elsewhere in this file) steal the grab mid-drag and start scrolling the
whole tab instead of moving the slider. `preventStealing` keeps this
`MouseArea`'s grab once pressed, regardless of how much vertical movement
happens along the way.

## Lock screen blur: `autoPaddingEnabled: false`

`LockScreen.qml`'s background-blur `MultiEffect` sets
`autoPaddingEnabled: false`. The wallpaper already fully covers the
surface (no transparent edge the blur legitimately needs extra padding
for), and the default `true` was extending the blur's render bounds past
the surface's real edges — visible as a soft glow ring bleeding out
around the whole screen.

## Real bug: Settings gear icon always opened screens[0]'s settings

`SettingsWindow.qml`'s per-screen `IpcHandler` target
(`"settings_" + screenName`) exists because a caller that already knows
which screen it's on (Control Center's own gear icon, `bin/crux-focused-
ipc` for a keybind) needs to reach *that* screen's instance specifically.
Confirmed real bug before this existed: Control Center's gear icon always
opened Settings on `screens[0]`, never the screen Control Center itself
was open on. No `enabled` gate is needed on the per-screen handler since
the name itself is already unique per screen.

## Real bug: Appearance color tab was silently inert

`AppearanceColorsSubTab.qml` now edits the v2 tonal-spot theme roles
directly (`Settings.data.theme.primary`, `.surface`, etc.) — it
previously only edited the legacy `mPrimary`/`mSurface`/... roles kept
around for pre-v2 widgets, which nothing in the actual v2 UI reads
anymore. Every preset pick and manual color edit on that tab was
silently inert (no error, no visible effect) until this was caught and
fixed to target the roles that actually paint the app.

## Bar.qml section positioning: anchors, centering, and edge-pinning bugs

`Bar.qml` positions its three `BarSection`s (`left`/`center`/`right`) with
plain `x`/`y` bindings, not `anchors` — Qt's anchor system doesn't
reliably react when a section's height changes via the `_sizeVersion`
workaround in `BarSection.qml` (confirmed via `console.log`:
`implicitHeight` itself settles to the correct value, but an anchored
`bottom`/`centerIn` position computed from it does not, staying stuck
using the height from before the workaround kicked in). Plain bindings
read `width`/`height` directly and don't go through that broken path.
`"left"`/`"right"` section ids stay the same regardless of bar
orientation (`Settings.data.bar.widgets` is keyed by them either way) —
only which screen edge they sit against changes.

**Center section**: must center on its own *visible* content, not the box
including the trailing drop-zone (see `BarSection.qml`'s `trailingSize`)
— otherwise the invisible zone's width skews the real widgets off
true-center by half its size. `trailingSize` only ever applies on the
section's *main* axis (horizontal when the bar is horizontal, vertical
when it's a side bar) — applying it to both `x` and `y` unconditionally
was a real bug: it threw off the *cross*-axis centering too (the module
visibly dropped out of vertical center on a horizontal bar).

**Right section**: always pinned to the true far screen edge. An earlier
"pull toward center when the gap looks big" clamp (`maxSectionGap`)
actively worked against this on wider screens — it compared the true
edge-anchored position against `centerSection`'s edge plus a fixed
budget and picked whichever was smaller, which on a roomy monitor meant
the smaller (more-central, short-of-the-edge) position won even though
there was plenty of room to just hug the edge. A right-aligned bar group
should hug the actual edge, full stop. It's shifted right/down by
`trailingSize` so the *visible* last widget (not the invisible trailing
drop-zone tacked on after it) is what actually touches `contentPadding`
from the true edge — the drop-zone's tail is allowed to hang slightly
past the window's own edge, which is fine since it's invisible.

## Real bug: bar module background opacity sliders did nothing

`BarModule.qml`'s background opacity was hardcoded to the fixed
`Tokens.barModuleOpacity` (0.88) instead of reading
`Settings.data.bar.useSeparateOpacity` to pick between `theme.barOpacity`
(Appearance tab) and `bar.backgroundOpacity` (Bar Layout tab) — so
neither settings-panel slider ever did anything, with no error to
indicate why.

## Wifi scanner ref-counting and the same dead-forgetRow() bug

`WifiPanelContent.qml`: nearby (unconnected) networks only show up once
the device's scanner is switched on — `Quickshell.Networking` doesn't
scan passively. `scannerEnabled` lives on the shared `WifiDevice` with no
ref-counting of its own, so the panel tracks which device *it* turned the
scanner on for and releases exactly that one when it goes inactive,
rather than blindly toggling the shared property.

Separately (already fixed earlier this session, see the "wifi popup:
wire the dead forgetRow()" commit): `forgetRow()`/`network.forget()` were
fully implemented but nothing in the UI ever called them — a known
network could never actually be forgotten short of `nmcli` by hand.

## Real bug, recurring pattern: per-screen IPC target gated to screens[0]

`ControlCenterWindow.qml`, `LauncherWindow.qml`, and `SystemStatsWindow.
qml` all needed a screen-specific IPC target name (e.g.
`"controlCenter_DP-1"`, not just `"controlCenter"`) — each of these
windows is instantiated once *per screen*, and a bar widget must reach
*its own screen's* instance specifically. Confirmed real bug, same root
cause in all three: gating a single shared target to `enabled: root.
targetScreen === Quickshell.screens[0]` meant every screen's click opened
screen 0's popup, not the screen the click happened on. This is a
different bug from the "gate a singleton behavior to one instance via
screens[0]" pattern (the old per-popup IPC guard) — that pattern is fine for
things that should only run once shell-wide (e.g. `NightLight.qml`
managing the one `wlsunset` process); it's wrong for anything the user
expects to open *on the screen they clicked from*. When adding a new
per-screen popup, give it a `"name_" + screenName` target from the start.

## Chamfer inside a Layout needs a sized wrapper Item

Every `Chamfer` that sits inside a `Layout` (RowLayout/ColumnLayout/
GridLayout) needs to be wrapped in a fixed-size plain `Item` rather than
having `Layout.*` properties set directly on the `Chamfer`/`Shape`
itself. A `Shape`'s own implicit sizing (derived from its rendered path,
itself derived from its `width`/`height`) fights the Layout-assigned
width when there's no `anchors.fill` in between, producing an infinite
`"binding loop detected for property _points"` warning at startup
(`LauncherWindow.qml` hit this once — every other `Chamfer` in the app
already went through a sized wrapper). Confirmed bounded when it does
happen (log stops growing, CPU stays idle, panel still renders/functions
correctly) but avoid it by always wrapping.

## QsMenuPopup: DBusMenu icons aren't always theme names

`QsMenuPopup.qml`: a DBusMenu entry's `icon` can be a bare icon-theme
name (needs `Quickshell.iconPath()` to resolve through the theme) *or* an
absolute file path/URL straight from the app — `Quickshell.iconPath()`
wrongly tries to look the latter up as a theme name and fails, rendering
a broken-image glyph (confirmed via screenshot). Use the icon string
directly whenever it already looks like a path or URL, only route bare
names through `iconPath()`.

Separately: `QsMenuPopup` is loaded by URL through a `Loader`, not
instantiated as `QsMenuPopup { ... }` directly — QML rejects a component
instantiating itself by type name from within its own definition
("QsMenuPopup is instantiated recursively"), but a `Loader` resolving the
same file by source URL is a dynamic load, not a static self-reference,
and works fine.

## Power menu tile tints: only Reboot/Shutdown are permanent

`PowerMenuWindow.qml` (spec §6.9): only REBOOT (tertiary icon) and
SHUTDOWN (error border + text) carry a permanent color tint,
unconditionally, whether selected or not — every other tile (including
LOCK) is neutral until selected. A real bug had every tile defaulting to
a "primary" tint even unselected/unarmed, so LOCK/SUSPEND/LOGOUT all
showed a permanently primary-colored icon/text — conflating "LOCK is
default-focused" (a one-time initial *selection* state) with LOCK having
its own permanent color, which the spec never called for.

## WeatherIcon cloud: filled circles, not a chained stroked arc path

`WeatherIcon.qml` draws its cloud glyph as filled overlapping circles,
not a single stroked multi-arc path. Chaining `ctx.arc()` calls with
mismatched start/end angles into one stroked outline self-intersected
into a tangled scribble at small sizes (confirmed by screenshot: looked
fine-ish at 40px, a garbled knot at 22px). Four solid circles filled
together (nonzero winding rule fuses overlapping closed loops cleanly, no
chained-arc discontinuities to go wrong) reads as a simple, robust cloud
silhouette at any size — prefer filled overlapping shapes over chained
stroked arcs for small Canvas glyphs generally.

## Real bug: Tokens.fontFamily ignored the General tab's font picker

`Tokens.fontFamily` was hardcoded to `"JetBrains Mono"` regardless of the
General settings tab's own font picker (`Settings.data.ui.fontFamily`) —
since nearly every widget reads `Tokens.fontFamily`, that setting
silently did nothing anywhere in the app. Fixed to read
`Settings.data.ui.fontFamily` (with the hardcoded string kept only as the
fallback for before `Settings.isLoaded`). Found via the user asking why
the SDDM greeter's clock font differed from the rest of the app — the
greeter's sync script used the *real* setting, exposing that the live
app was still on the hardcoded one.

## Plugin Widget.qml resolves qs.* imports despite living outside the tree

`Plugins.qml`: a plugin's `Widget.qml` (loaded the same way a built-in
bar widget is, via `BarWidgetLoader.qml`) can still `import qs.Commons`/
`qs.Modules.Bar.Extras`/etc even though the plugin file itself lives
outside the `qs.*` module tree (`~/.config/crux/plugins/<name>/`) —
because those modules were already registered by `shell.qml`'s own
static imports before any `Loader` ever touches the plugin file. This
only works because every `qs.*` dir crux actually uses is statically
imported somewhere already; a dynamically-`Loader`-loaded file can't
resolve a `qs.*` module namespace that *nothing* has statically imported
yet (same root cause as the `SettingsWindow` import-registration trick in
`shell.qml`).

## Verifying UI changes when the desktop is covered by fullscreen windows

`grim -o <output>` just captures whatever's on screen — if every workspace
on a monitor has a fullscreen app, you can't see the wallpaper/bar layer no
matter how many times you re-screenshot. Check for an actually-empty
workspace first (`hyprctl workspaces -j`, look for `"windows": 0`), switch
the target monitor to it (`hyprctl dispatch "hl.dsp.focus({ workspace = N
})"` — Lua-shorthand dispatch, see [`hyprland.md`](hyprland.md) for why),
*then* screenshot. Don't conclude a feature is broken from a screenshot
that never actually had a chance to show it.

## Popups call each other directly, not over IPC

Bar widgets used to open a popup by shelling out to
`qs ipc -c crux call <target> openAt ...` — forking a process to send a
message back into the process that sent it, once per click. `Commons/Popups.qml`
is an in-process registry keyed by name + screen, so a widget calls the popup
object directly. The `IpcHandler`s stay: they're the entry point for genuinely
external callers (keybinds, scripts), which is what IPC is for.

Every registered surface implements the same contract — `open()`, `close()`,
`toggle()`, optionally `openAt(x, y)`. `SlideCard` originally exposed `open` as
a *bool property*, so `Popups.open()` silently did nothing on every card; its
property is `shown` now and the four are real functions.

`Commons/PopupRegistration.qml` exists because a surface created inside a bar
widget (SettingsWindow, PowerMenuWindow, the launcher/calendar/media windows)
receives its `screen` from BarWidgetLoader *after* construction. Registering
from `Component.onCompleted` alone put it under an empty screen key, where the
other monitor's instance promptly overwrote it — one monitor's icon then opened
the other monitor's window. It re-registers on `screenChanged`, and tracks a
separate `registered` bool so the placeholder entry made before the screen
arrives gets cleaned up rather than left dangling.

## Screen-agnostic popup aliases must exist once, not per monitor

Each popup exposes `"<name>_<screen>"` (what a bar icon calls, since it knows
its own screen) and a plain `"<name>"` alias for keybinds. The alias used to be
declared by *every* per-monitor instance, gated on
`targetScreen.name === Hyprland.focusedMonitor.name`. On a focus change both
instances are briefly enabled, they race for the same target name, and
Quickshell drops the loser:

    IpcHandler ... registered but will not be used because another handler
    is registered for target wifi

after which the alias could stay bound to the monitor that no longer has focus.
It affected all 19 aliased popups, and only ever appeared *after*
"Configuration Loaded", so a boot-log check never caught it.

`PopupAlias`/`PopupAliases` now declare each alias once for the whole shell,
instantiated in `shell.qml` outside `Variants`, resolving the focused monitor at
call time through the registry.

## Services own their hardware, not the widget that happens to show it

Two bugs of the same shape, both fixed by extracting a singleton:

**Keep-awake** had two unrelated implementations — the Control Center tile drove
a Wayland `IdleInhibitor` off `Settings.data.general.keepAwake`, while the
KeepAwake bar widget ran its own `systemd-inhibit` subprocess against a local
bool nothing else could see. Toggling either left the other showing the opposite
state. `Commons/IdleInhibitorService.qml` owns it; state lives in Settings so it
survives a restart. Two layers back it because they stop different things: the
compositor's idle notifications (the `IdleInhibitor` stays in
ControlCenterWindow, which has the window it needs to attach to) and logind's
own idle/sleep handling (`systemd-inhibit`). `Commons/Idle.qml` additionally
refuses to schedule a stage while inhibited — it never consulted keepAwake at
all, so crux's own screenOff/lock/suspend could fire while the UI insisted the
machine was held awake.

**Night light** kept all its wlsunset handling inside the NightLight bar widget,
gated on "am I the instance on `Quickshell.screens[0]`" because bar widgets exist
once per monitor. Night light therefore only worked when that widget happened to
be on the bar — the Control Center's own toggle was a dead placeholder, and
flipping the setting by hand did nothing either. A singleton is single by
construction, so `Commons/NightLightService.qml` drops the primary-instance
handling entirely along with the workaround for `screen` arriving after
`Component.onCompleted`.

## PowerProfiles.hasPerformanceProfile is false for the first second

`Quickshell.Services.UPower`'s `PowerProfiles` fetches its properties over DBus
after construction, so `hasPerformanceProfile` reads false at startup and flips
true a second or two later (confirmed by probing at 0s and 2s). Anything that
gates visibility on a one-shot read of it stays hidden for the whole session —
`PowerProfileService.available` has to stay a binding.

Writing the profile is polkit-gated, and a refusal surfaces only as a log
warning while the property keeps its old value. The service verifies the write
landed and toasts if it didn't, rather than leaving a bar icon that just doesn't
respond. The usual cause is crux running outside the seated login session: a
terminal that places itself in its own systemd scope under `user@1000.service`
means polkit sees no active session for the caller, and
`org.freedesktop.UPower.PowerProfiles.switch-profile` is `allow_active`.

## Colour schemes are data, not QML

`Assets/ColorSchemes/*.json` shipped ten palettes nothing referenced, while
AppearanceColorsSubTab carried its own five inline in 91 lines. The shipped
files were in noctalia's m-prefixed shape, which crux's `Color` singleton
stopped using. `Commons/ColorSchemes.qml` reads the directory now, so adding a
scheme is dropping in a file, and every palette loads in one pass because the
picker draws a swatch of each.

Where both curations had the same scheme they disagreed on accents (noctalia's
Gruvbox primary is #b8bb26, crux's #fabd2f); crux's hand-tuned values won, and
the seven noctalia-only palettes were converted with derived container tones —
surfaceContainerLow/High and outlineVariant by mixing along the surface ramp,
primaryContainer as primary*0.36, checked against the three schemes present in
both. The `light` blocks were dropped in that conversion, so presets are
currently dark-only; they're recoverable from `d3e2e43^`.

## Icons: recolour symbolic, leave app icons alone

Symbolic icon themes ship one fixed colour, usually light because they assume a
dark shell — so in light mode white glyphs sat on white surfaces and vanished.
`Widgets/NIcon.qml` recolours them, porting noctalia's `appicon_colorize.frag`
("tray" path: max-channel intensity through a smoothstep, which evens out glyphs
of differing weights). The tray and the launcher pass `colorize: false`, because
those are real app-icon logos that are legible either way and would be flattened
to one tone.

`NIcon` sizes its `IconImage` explicitly rather than anchoring it to fill.
Filling made it request a raster buffer before geometry settled, and Qt answered
with "requested buffer size is too big, ignoring" — 159 times from the launcher's
app list alone.

Two colour traps worth remembering. An icon on a `Colors.primary` fill needs
`Colors.primaryText` (matugen's `on_primary`), *not* `primaryContainerText` —
that's the on-colour for `primaryContainer`, and pairing it with `primary` put
#ffdcbf on #ffb873. And recolouring flattens an icon that carried meaningful
colour of its own: breeze's `media-record.svg` is #da4453, so the Control
Center's RECORD tile sets `iconColor: Colors.error` to keep a red dot that also
follows the theme.

The configured icon theme may not be where crux's glyphs come from at all. On
this machine `pixora-dark` is an app-icon theme — 790 files under
apps/places/categories/mimetypes, and not one of the ten symbolic names crux
draws. Every shell glyph resolves through its `Inherits=breeze-dark` line. That
works, but it means crux depends on a theme it never names, which is why every
call site passes a non-symbolic fallback.

## Bar pills expand, so the sections have to give

`BarPill` collapses to the standard 32px chamfered cell and expands to reveal a
label — noctalia's bar behaviour, which is plain width/opacity animation and not
a shader (every shader in noctalia's bar is `appicon_colorize`, which only
recolours icons). Animating implicitWidth/implicitHeight is enough for the
section to follow, because BarSection sizes itself by summing item widths and
re-reading on their change signals.

The three bar sections are positioned independently, so a growing section slid
straight over its neighbour. Centre yields now — centred while there's room,
pushed clear otherwise — but positioning can't fix a capacity problem, so a
pill's label is bounded and elides. `forceOpen` on several widgets at once
over-subscribes a narrow bar; hover-only expansion costs nothing.

## NText tracking is opt-in

The spec gives each type tier a letter-spacing, and `NText` applied it
automatically at first. Most existing layouts were measured without it, so text
got wider and started clipping — "fields" rendered as "fiel". Tracking is a
per-call-site flag; the 161 blocks that had set `font.letterSpacing` explicitly
were given `tracking: true` when they were migrated.

## The joined drawer outline

Added 2026-10-17, replacing the fillets below. A drawer read as a separate box because it was outlined and the docked bar strip wasn't, so its strokes just stopped at the bar. Now, when the bar is a docked strip (`showBackground` on, `floating` off), `shell.qml` draws a 1px `Colors.outline` line along the bar's inner edge, and `SlideCard` (`joined`) moves in by `Tokens.borderPanel` so it overlaps that line. The card's fill erases the line along the shared edge, and its open stroke turns into the bar line at both ends, giving one continuous outline. The strip is `Tokens.barJoinGap` deeper than `bar.thickness` on its inner side, so the line stands clear of the module outlines instead of touching them; the modules keep the configured thickness. The card also takes the strip's fill and opacity, so the two read as one surface; the grouped sections stay the raised layer on top.

A floating bar with a strip (`Tokens.barPill`) is the same idea as one outlined pill: the strip carries `Colors.outline`, the group plates inside it are hidden so no edge doubles up, and drawers join the pill's outline the way they join the docked line. The pill cuts `cutTopRight` + `cutBottomLeft`, opposite corners at its two ends, so the power button at the end nests parallel to it. While the bar floats, every drawer morphs out of the module that opened it (`openFrom` passes the module's size), centred on it and clamped to the bar's ends. Bar widgets map positions into the bar window, which a floating bar insets by its margin, so `SlideCard` adds `Tokens.barMargin` to convert them. An "islands" variant (no strip, drawers sharing a group's edge) was built and compared on 2026-10-17; it reads as stacked boxes rather than one shape, so it was dropped.

`Chamfer`'s open stroke uses `SquareCap`. Its run starts half a stroke in from the omitted edge, so a flat cap left the corner pixel of the join unpainted, a 1px notch visible in every capture.

## The drawer fillet (ConcaveCorner)

**Removed 2026-10-14 — the user found the flared joint sloppy.** SlideCard
now meets the bar with straight sides and no fillets; only the two far
corners are chamfered, and the rim light is off on the bar-facing edge (it
drew a seam there once the fillets stopped covering its ends). Don't bring
the fillets back. `ConcaveCorner.qml` stays in the UI kit, unused. The
history below is kept for context.

A popup that opens off the bar used to read as a separate box parked next
to a strip. noctalia solves this with a concave corner at each end of the
shared edge, so the panel appears to flare outward and merge into the bar.
Its version lives in `Modules/MainScreen/Backgrounds/ShapeCornerHelper.qml`
— a per-corner inversion built from `PathArc` direction plus sign
multipliers. crux's `Widgets/ConcaveCorner.qml` draws one corner and
rotates it 0/90/180/270 instead; the geometry is identical every time, so
four hand-written variants would be four places to get it wrong.

Two things were not obvious:

**Fill alone is invisible.** noctalia's panels are solid surfaces, so a
fillet filled with the panel colour is all it needs. crux's panels read by
their *outline* — over a dark wallpaper a surface-coloured fillet is
indistinguishable from the desktop behind it. `ConcaveCorner` therefore
strokes the arc as well, and only the arc: its two straight legs sit flush
against the panel and the bar, so stroking them would draw a seam through
the exact junction the shape exists to hide.

**The card's own stroke has to get out of the way.** With
`omitStrokeSide` the card already skips the edge touching the bar, but its
two side strokes still ran the full height. The arc leaves the side one
`cornerSize` below that edge, so the leftover stub above the tangent point
made the junction render as a Y. `Chamfer.strokeTrim` pulls both free ends
of the open stroke back along their own edges by that distance; the side
stroke now ends exactly where the arc picks it up.

`SlideCard` keeps `clip: false` and moved its clipped content into an
inner `body` item — the fillets deliberately paint outside the card's
bounds, while the collapse animation still needs the content clipped.

Verifying this needed rendered pixels, not logs: every wrong version above
booted clean. Tinting `_cornerFill` bright red and counting matching
pixels in a `grim` capture located the shapes; column probes
(`im.getpixel` down a few x values across the junction) gave the exact
tangent points.

## The tray drawer

Pinned tray icons stay in the bar; everything else hides behind a chevron
that slides them out **along the bar itself**, not into a popup — the
popup version was built first and rejected ("i want it to just open in the
bar, not a popout"). `Modules/Bar/Widgets/Tray.qml` holds the split, and
`Modules/Bar/Extras/TrayCell.qml` is the single cell both the pinned row
and the drawer use, so activate/menu/pin behave identically in each.

The reveal is a `clip: true` Item whose width (height on a vertical bar)
animates between 0 and its inner Grid's size, with the Grid pinned against
the chevron end so icons emerge from under it rather than shoving the
pinned ones aside. In a right-hand bar section the module's right edge is
fixed, so it grows leftward on its own — no per-section special casing.

The drawer collapses itself 5s after the pointer leaves it (`Timer` gated
on `running: expanded && !hovered && no open DBusMenu` — a Timer resets
whenever `running` goes false and back true, so hovering restarts the full
countdown rather than pausing a partial one). The menu guard matters: an
open DBusMenu belongs to a drawer icon, and collapsing out from under it
would leave the menu anchored to nothing.

Pinning is stored per widget instance in `bar.widgets[section][i].pinned`,
against the tray item's **`id`**, not its title: a title carries transient
state (an unread count) and would silently unpin the item when it changed.
Pin/unpin is a footer row appended to the item's own DBusMenu in
`QsMenuPopup` (`pinLabel` + `pinToggled`), plus middle-click on any cell.

Three dependency-tracking traps, all confirmed live, all silent:

1. **`TrayModel.visibleItems()` reading `SystemTray.items.values` itself**
   never re-ran. The caller has to do that read in its own binding and pass
   the list in.
2. Even then, `drawerItems: TrayModel.unpinnedOf(root.allItems, root.pinned)`
   stayed empty while a direct call with the same arguments returned 1 —
   logged side by side. A binding whose whole body is a call into a
   singleton is the same shape as the `itemAt()` case above. Fix: do the
   filtering inline in the binding so every dependency is a plain property
   read; `TrayModel` keeps only the leaf helpers (`key`, `label`, icons,
   `togglePin`).
3. `visible: ... || chevron.visible` — reading a grandchild's property from
   the root's own binding — never re-evaluated either, so the whole widget
   stayed hidden with a perfectly clean boot log. Fix: a root-level
   `hasDrawer` both the root and the chevron read.

Per-instance widget settings needed wiring first: `widgetData` was declared
on `CustomButton` and `Spacer` but nothing ever assigned it, so those two
had been reading an empty object since they were written. `BarSection`
now passes `wrapper.modelData` into `BarWidgetLoader`, which forwards it
like the other guarded properties, and `Settings.updateBarWidget()` merges
keys back with the same screen-override rule as the reorder functions.

## Updates: promoted from plugin to built-in widget

The update counter started as a local plugin under
`~/.config/crux/plugins/updates/` (see `Commons/Plugins.qml`) on the
reasoning that it was optional and package-manager-specific. It is now
`Modules/Bar/Widgets/Updates.qml`, registered in `BarWidgetRegistry` like
any other widget. What changed with the move:

- Config left its own `config.json` + `FileView`/`JsonAdapter` pair for
  `Settings.data.updates`, with a real `UpdatesTab` in the settings panel
  and entries in `SettingsSearchIndex`. The bespoke right-click
  `SettingsWindow.qml` is gone — right-click now does
  `Popups.openTab("settings", screen, "updates")` like the rest of crux.
- The IPC target went from `pluginUpdates_<screen>` to `updates_<screen>`, and later to one global `updates` target (see below).
- The old plugin dir was moved to
  `~/.local/share/crux/retired-plugins/updates`, not deleted. A built-in
  shadows a plugin of the same id (`BarWidgetLoader` checks `_isBuiltin`
  first), so leaving it in place would have been harmless but dead.

The settings-json key and the default values match what the plugin's
`config.json` already held, so nothing needed migrating.

## Updates: post-update recheck across monitors

`~/.config/crux/plugins/updates/Widget.qml` chained `qs ipc call pluginUpdates_<screen> check` onto the update command, which only rechecked the bar the update was launched from. There was one instance per monitor, so every other bar kept showing a stale count (and stayed visible at 0) until its own 5-300 minute timer came round.

The count now lives in `Services/UpdatesService.qml`, so there is one check for all bars and one global `updates` IPC target. The update itself runs in a terminal crux can't watch, so the command still ends by writing `~/.cache/crux/update-count-stamp`, and the service rechecks when that file changes. `checkupdates` is a read-only sync that never touches the live pacman database or lock; AUR updates come from `yay -Qua`, a local query, when yay is installed.

## The chamfer end-cap rule only worked on 8 of 36 widgets

`BarSection` computed the v5 invert rule correctly the whole time, but
`BarWidgetLoader` only forwards `invertChamfer` to a widget that actually
declares the property, and 28 bar widgets never did — so the rule silently
applied to whichever of the 8 happened to sit at an end. `ControlCenter`
was worse: it declared no root property *and* hardcoded
`invertChamfer: false` on its own `BarModule`, with a comment arguing the
non-inverted cut lined up better with the outer bar strip. It sits at left
index 0 in the default layout, so the bar's left end-cap never inverted and
never mirrored the right one. The user asked for both end-caps to angle
inward, which overrides that older reasoning.

All three containers (`BarModule`, `BarPill`, `BarIconButton`) already
supported the property, so the fix was two mechanical lines per widget.
`Spacer` is the one exemption — it has no visual container.

The general lesson: a rule computed in `BarSection` reaches a widget only
through the guarded `item.<prop> !== undefined` forwarding in
`BarWidgetLoader`. Adding a new forwarded property means adding it to every
widget, or it silently no-ops on the ones that lack it — the same shape as
the `widgetData` bug (declared on two widgets, never assigned by anyone).

## The wallpaper slice strip

The wallpaper browser copies skwd-wall's "slices" view: a horizontal `ListView` of parallelograms, the focused one widened into the preview card. skwd-wall itself was dropped from crux because it lagged, and its slice delegate shows why: every slice is an offscreen layer with a `MultiEffect` mask, plus a second shape for its shadow, all re-rendered while the strip animates. crux's old grid had the same per-thumbnail `MultiEffect` pattern.

`WallpaperSlice.qml` gets the slant without layers: each slice is one `Shape` whose parallelogram path is filled with the image itself (`ShapePath.fillItem`, centred by `fillTransform`), so `Shape.CurveRenderer` anti-aliases the slanted edges. The first version sheared a clipping container instead; that also avoided layers, but Qt clips a transformed item through the stencil buffer, which is aliased, and the unfocused slices' slants showed as stairs. The source `Image` is never drawn itself and keeps its decoded pixel size, so the texture maps 1:1. Each image decodes once at the expanded size (`sourceSize`), so focusing a slice never re-decodes it. Measured on DP-1 with the stencil version: stepping through 20 slices in 3 seconds cost about 6% of one core.

Opening the browser used to decode every original (141 megapixels here) each time, about 1.4s of CPU, because the image cache is too small to keep them. After each scan a bash job writes a 576px-tall JPEG per image to `~/.cache/crux/wallpaper-thumbs`, keyed on path and mtime, and slices load those: an open now costs about 0.46s. Without ImageMagick the job exits and slices fall back to the originals.

Wallhaven results use a plain `GridView` instead: thumbnails sit 3px inside a 5px chamfer, which is enough for their corners to clear the cut without any mask.


## Chamfered window corners

Hyprland can only round all four corners the same way. `rounding_power = 1` turns its superellipse into a 45° cut, but that cut is symmetric, and its border shader insets the diagonal using L1 distance, so by its own math the cut edge works out √2 thinner than the straight ones. Crux's corner language is asymmetric (top-right and bottom-left), which needed real shader work.

A C++ plugin would have been the usual route. Hyprland 0.56 reads shader overrides from a directory and swaps them in at runtime with `hyprctl reloadshaders <dir>`, keeping the old set if loading fails. Replacing `rounding.glsl` and `border.glsl` covers the window clip and the border without a plugin's per-version rebuilds or its ability to crash the session.

The per-corner mask travels in `rounding_power`, because that is the only per-window float that reaches both shaders. The blurred background behind translucent windows is always drawn with a hardcoded power of 2, so the default mask is chosen for any value outside the encoded range. Blur and border then agree for every window that doesn't override its mask.

Which corner a fragment belongs to is read from the texcoord derivatives, not from `gl_FragCoord`. On the rotated DP-1, framebuffer space is turned 270° from the window, and the first version cut the bottom-left corner when it meant the top-left. `dFdx`/`dFdy` of `v_texcoord` map a framebuffer offset back into the surface's own orientation, and they also stay correct for cropped surfaces, where the texcoord centre isn't 0.5.

The outer cut is the inner one plus `thick * (2 - √2)`. That keeps the diagonal parallel to the window's own cut and gives it the same perpendicular width as the edges, which is the same offset `Chamfer.qml` applies to its stroke.

## The bar backdrop

Hyprland's scrolling layout keeps drawing columns that are scrolled off-screen, and it doesn't clip them to the work area. With three or more windows on a workspace, the column above the focused one ends a few pixels inside the bar's reserved strip, so a slice of it showed through the translucent bar and the gap around the floating pill.

`BarBackdrop` is a Top-layer window that covers the whole strip plus Hyprland's `gaps_out` on that edge (`barExtent + barMargin + gaps_out`, read by `Services/HyprGaps.qml`), because a scrolled-off window can end anywhere above the work area, not just inside the reserved zone. It draws the wallpaper with the same `PreserveAspectCrop` as `Background`, so it reads as the wallpaper itself. The wallpaper is solid up to the bar's outer edge (`barExtent`) and fades out across the bar margin and `gaps_out`, so a window scrolling up dissolves into it instead of being sliced off along a hard line. The fade ends exactly where the work area starts, so the focused window is never dimmed. `MultiEffect` only treats a gradient mask as a smooth ramp with `maskThresholdMin: 0.5` and `maskSpreadAtMin: 1`. With a threshold of 0, every pixel with any alpha is fully opaque. The bar window could not simply grow to cover its margins, because every bar widget anchors its popup from window coordinates plus `Tokens.barMargin`.

Within a layer, Hyprland stacks surfaces in the order they are created, so the bar's `visible` waits on the backdrop's. The backdrop does not follow wallpaper-switch transitions, so the strip snaps to the new image while the rest of the screen animates. With auto-hide on, the bar reserves no space and the backdrop stays unmapped.

## Long-running child processes

QuickShell stops a `Process` when crux quits normally, but not when crux crashes or is killed with `kill -9`, which is how the dev loop restarts it. Children that never exit by themselves were reparented to init and kept running. Every restart added another pair of clipboard watchers, so each copy was stored several times, and an orphaned `systemd-inhibit` would keep the machine awake with no toggle left to turn it off.

Every long-running child is therefore started through `setpriv --pdeathsig TERM`, so the kernel signals it when crux dies. The flag survives `exec`, so a `sh -c '... | exec cava'` wrapper passes it on to cava. `systemd-inhibit` stops its own `sleep infinity` when it gets SIGTERM, so keep-awake only needs the flag on `systemd-inhibit`. One-shot commands that exit on their own don't need it.

A singleton that owns such a child must exist once. The clipboard watchers used to live in `ClipboardPopupContent`, which PopupHost builds once per monitor, so two pairs ran side by side.
