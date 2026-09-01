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
2. **Appearance / ColorScheme** — done (2026-08-31). The "Templates" piece
   was already done, just living under the Wallpaper tab instead of
   Appearance/Colors: `WallpaperTab.qml`'s "System templates" section
   generates config for 10 apps (Hyprland, Kitty, GTK, Qt, Yazi, Discord,
   Pywalfox, btop, Starship, SDDM greeter) via `bin/theme-templates/`. The
   one genuinely missing piece — gsettings sync — is now built too: a
   new `templates.gsettings` toggle runs `gsettings set
   org.gnome.desktop.interface color-scheme prefer-dark` on regenerate,
   so GTK4/libadwaita apps render dark chrome even though crux ships no
   full GTK theme package for `gtk-theme` itself to point at.
3. **Bar** — mostly done (2026-08-31). Density is now a real feature: two
   preset action-buttons ("Comfortable"/"Compact") in `BarLayoutSubTab.qml`
   that batch-set thickness/widgetSpacing/contentPadding — not a stored
   mode, since the underlying sliders were already independently tunable
   and a fourth persisted "density" property would just be redundant state
   to keep in sync. Background opacity separate from overall theme opacity
   already existed (`useSeparateOpacity`/`backgroundOpacity`) — this item's
   "not confirmed present" was itself stale. **Capsule/pill background per
   widget-group deliberately not built** — crux's whole visual language is
   chamfered corners with an explicit "no radius" rule (see
   `ControlCenterWindow.qml`'s one deliberate circular-avatar exception,
   which calls out radius as the departure); grafting noctalia's rounded
   pill grouping on top would fight the app's own established identity, not
   extend it. Skip unless a future request explicitly wants rounded
   grouping as a real design change, not a checkbox-parity copy.
4. **Audio** — still just Volume/Output/Input devices (confirmed current
   `AudioTab.qml` state). Media (player integration prefs) and Visualizer
   (waveform/spectrum) subtabs not built.
5. **Wallpaper** — done, and was already done when this doc first flagged
   it open (stale entry, corrected 2026-08-31 after actually reading
   `WallpaperTab.qml`/`WallpaperBrowserWindow.qml` instead of trusting the
   crux skill's older "not yet ported" note). Has a real thumbnail picker,
   matugen auto-theme with all 9 scheme types + color-index cycling, a
   6-type shader transition picker, auto-cycle automation with a real
   `Timer` driving it in `shell.qml`, a Wallhaven API key field, a 10-app
   system-templates retheming list, and a full 1417-line Wallhaven search
   browser (SUPER+W) with purity/resolution filtering and delete. The crux
   skill's "Wallpaper + theming (not yet ported to crux)" section is
   itself stale and should be updated or removed next time that file's
   touched.
6. **Launcher** — settings (fuzzy-match behavior, result count, clipboard
   history size/ignored MIME types, custom command prefixes) not built; the
   launcher + clipboard widgets themselves work but are unconfigurable.

## Tier 2 — remaining real feature gaps

1. **Control Center settings tab** — done (2026-08-31). Most of the popup's
   rows are live system state, not preferences (Wifi/Bluetooth/audio/
   brightness stay hardcoded-to-reality on purpose) — the tab covers the
   handful of genuinely-hardcoded constants that were there: weather
   card visibility, temperature unit (F/C, actually re-requests the
   forecast in the right unit from open-meteo), the stats-gauge refresh
   interval (was a hardcoded 2000ms Timer), and the CAPTURE tile's
   screenshot command (was hardcoded to `rishot`, now a text field run
   through `sh -c` so flags work).
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

**Update 2026-08-31**: the working tree is committed and pushed (own
Forgejo remote), `FuzzySort.qml` is wired into a real search sidebar, and
Control Center has its settings tab. Wallpaper turned out to already be
done (this doc had it wrong — see Tier 1 §5). Remaining highest-value
items, roughly in order: Tier 1 §2 (Appearance Templates + sync-system-
theme) is the next "feels finished" win per hour; Tier 1 §1/§3/§4/§6
(General fonts/scrolling, Bar density/capsule, Audio Media/Visualizer,
Launcher settings) are all smaller expose-what-exists passes; Tier 2 §2
(Dock) and §3 (Connections tab) are the remaining real builds, both
optional/low-priority per their own entries above.

This is your call to reorder — ping me with whichever number(s) you want to
start on and we'll take it one confirmed step at a time.
