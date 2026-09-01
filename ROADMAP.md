# crux roadmap: closing the gap with noctalia

Context: noctalia v5 is dropping QuickShell, and the goal is for crux to stop
being "the downstream shell" — a real daily driver with noctalia-level depth,
built and understood from the ground up rather than ported wholesale (crux
has deliberately never copied noctalia's ~5400-line `Ui`/`Commons` kit, its
telemetry, its setup wizard, or its plugin marketplace — see "Porting from
Omarchy" in the crux skill for why).

This is a scope map, not a sprint plan. Each numbered item is its own
multi-step build (own settings tab, own widget/service, own boot-tested
pass) — nothing here should be batched. Work through it in whatever order
you actually want; the tiers below are my read on value-vs-cost, not a
mandate.

**Status as of 2026-08-31**: crux is now the confirmed daily driver on both
this user's account and Mia's. The settings panel has grown from the
original 6 tabs to 18 (General, Bar, Appearance, Audio, Hue, Display, System
Monitor, Wallpaper, Desktop Widgets, OSD, Session Menu, Lock Screen, Idle,
Notifications, Peripherals, Hooks, Plugins, About) — most of old Tier 2 and
Tier 3 is now built. Everything below has been re-verified against the
actual repo state, not just this doc's original guesses.

---

## Done since this doc was first written

Kept here (not deleted) so it's clear what's no longer open work:

- **OSD settings**, **About tab**, **Session menu settings**, **Idle
  handling**, **Notifications**, **Display (brightness + night light)**,
  **Lock screen** (full PAM-backed rewrite, SDDM theme, per-monitor gating,
  lockout timer) — all built, each with a real settings tab.
- **Hue** — built despite Tier 3's "skip unless you own hardware" framing.
- **Desktop Widgets** — built (`Modules/Background/DesktopWidgets.qml` +
  `DesktopWidgetsTab.qml`).
- **Plugins system** and **Hooks** — both built, despite Tier 3's original
  "defer" framing for Plugins specifically (worth a note: this was framed as
  "baggage crux doesn't want" — if it's grown into something more than a
  stub, worth double-checking it didn't reintroduce the noctalia-marketplace
  complexity this doc originally wanted to avoid).
- **Peripherals** — new tab not anticipated by this doc at all; covers
  keyboard layout, lock-keys, and VPN in one grouped tab (mirrors how Audio
  groups all Pipewire settings together).
- Settings-panel overflow bug (tabs/content silently rendering past the
  card edge instead of scrolling) — found via audit, fixed across every
  affected tab.
- Noctalia-referencing description text — cleaned up across all tabs.

## Tier 0 — settings panel chrome (no new subsystems)

- **Pill-style tab switcher** — `SubTabBar.qml` exists and is in use; not
  re-verified pixel-for-pixel against noctalia's segmented-pill styling.
- **Fuzzy-search sidebar** — done (2026-08-31). `Commons/FuzzySort.qml` +
  `Modules/SettingsPanel/SettingsSearchIndex.qml` were both already fully
  built but unwired; wired a search box into `SettingsWindow.qml`'s sidebar
  (swaps the tab list for fuzzy-matched hits on `label`/`keywords` while
  typing) and added an `initialSubTab` bridge prop to every subtab-owning
  tab (General/Bar/Appearance/Display/LockScreen/Notifications/Idle/Hooks)
  so a search hit can land on the right subtab, not just the right
  top-level tab. Boot-verified clean; live click-through not done (rotated
  portrait monitor made input-injection coordinates unreliable enough to
  risk clicking the wrong window — verified by code-path inspection
  instead).
- **Reset-to-default icon buttons** — not built, no pattern for it anywhere
  in `Modules/SettingsPanel/Controls/`.

## Tier 1 — expand tabs crux already has

Still open, unchanged from original assessment (not re-diffed line-by-line
against noctalia this pass):

1. **General** — font pickers (default vs monospaced, independent size
   sliders), reverse-scrolling toggle, smooth-scrolling toggle likely still
   missing from `GeneralBasicsSubTab.qml`.
2. **Appearance / ColorScheme** — Templates subtab (matugen-style per-app
   config generation: kitty, GTK, etc.) and "sync system theme to gsettings"
   still not built.
3. **Bar** — density (comfortable/compact) and capsule/pill background
   options per widget-group not confirmed present in `BarLayoutSubTab.qml`.
4. **Audio** — still just Volume/Output/Input devices (confirmed current
   `AudioTab.qml` state). Media (player integration prefs) and Visualizer
   (waveform/spectrum) subtabs not built.
5. **Wallpaper** — still no picker UI, auto-cycle interval, or matugen
   `useWallpaperColors` toggle; the skwd wallpaper-picker port is still the
   real blocker here (per crux skill's open-work list).
6. **Launcher** — settings (fuzzy-match behavior, result count, clipboard
   history size/ignored MIME types, custom command prefixes) not built; the
   launcher + clipboard widgets themselves work but are unconfigurable.

## Tier 2 — remaining real feature gaps

1. **Control Center** — `ControlCenter.qml` widget + `ControlCenterWindow.qml`
   popup exist and work, but there's **no settings tab for it** in the
   18-tab list. Whatever's configurable about it today is hardcoded.
2. **Dock** — still not built at all. Genuinely optional — decide if you
   want one before sinking time here.
3. **Connections (Wifi/Bluetooth settings tab)** — still just the existing
   popups (`WifiMenuWindow`, `BluetoothMenuWindow`), no dedicated settings
   tab for saved networks/priority/forget-network/adapter selection. Still
   assessed as low priority relative to its size (noctalia's equivalent is
   ~2400 lines for "more knobs on a thing that already works").

## Tier 3 — niche / defer

- **Location** — still not built; bundle into Night-Light work if that ever
  needs real sunrise/sunset timing rather than building standalone.
- **Region** (date/locale formatting, per-panel clock format) — still not
  built; low urgency polish.

---

## What I'd personally sequence first

Two things stand out now that weren't true when this doc was first written:

1. **Commit the working tree.** 41 modified + ~15 new files are sitting
   uncommitted right now — the biggest actual risk to this whole push is
   losing it, not what to build next.
2. **Finish or remove `FuzzySort.qml`.** It's the one item on this list
   that's neither "done" nor "not started" — it's a half-built dependency
   nothing calls, and with 18 tabs now, a search box is more valuable than
   when this doc first floated the idea.

After that, Tier 1 items 2 and 5 (Appearance Templates, Wallpaper picker +
matugen) still get the most "feels finished" per hour, and Wallpaper
specifically replaces the hand-copied hex palette with the real pipeline.
Control Center's missing settings tab is the cheapest Tier 2 win since the
subsystem itself already exists.

But this is your call to reorder — ping me with whichever number(s) you want
to start on and we'll take it one confirmed step at a time.
