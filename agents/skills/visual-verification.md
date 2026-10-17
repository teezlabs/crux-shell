# Visual Verification

Read this before finishing any crux change with a visual effect: bar
widgets, popups and PopupHost cards, NPanelWindow surfaces, notifications,
OSD, wallpaper/theming, chamfers and depth, animations and
transitions (stills only, no video).

Visual changes must be verified in the running shell, not just a clean boot
log. A capture alone isn't verification: open it and look for clipping,
overlap, wrong spacing, stale state, focus problems and regressions against
the reference before calling the change done. Every wrong version of the
chamfer fillets booted clean — pixels were the only evidence.

## Prerequisites

1. The change is live: follow the kill → verify → launch → check-log loop in
   [`dev-loop.md`](dev-loop.md) as separate tool calls, and get a boot log with no `WARN`
   lines first.
2. The target layer is actually visible. If the monitor's workspace has a
   fullscreen window, switch to an empty one first (see [`docs/design-notes.md`](../../docs/design-notes.md), "Verifying
   UI changes when the desktop is covered by fullscreen windows").
3. Know which output to capture — this box has two (`DP-1` rotated portrait,
   `DP-2`). `hyprctl monitors -j` lists them; per-screen surfaces must be
   checked on both when the change depends on orientation or bar position.

Keep captures in the session scratchpad, not the repo or `~/Pictures`.

## Screenshots

`$S` below is the session scratchpad directory.

```bash
grim -o DP-2 "$S/before.png"             # one output
grim "$S/all.png"                        # every output, stitched
grim -g "6,256 42x1068" "$S/bar.png"     # a region, "X,Y WxH" in global coords
```

To crop to a crux surface, read its geometry from `hyprctl layers -j`
(namespaces are `crux-bar`, `crux-popup-host`, `crux-<popupName>`, …).

Capture **reference and candidate as separate images** when changing a
layer-shell surface or layout: grab `before.png` on the current build,
apply the change and relaunch, grab `after.png` with the same state open,
then compare both. For subtle differences, diff them:

```bash
magick compare -metric AE before.png after.png diff.png   # prints changed-pixel count
```

or probe pixels with Python/PIL (`im.getpixel`) — that's how the chamfer
tangent points were found. Tinting the element under test a loud color
(temporarily) and counting matching pixels locates it unambiguously.

## Driving the UI

Open surfaces through IPC rather than clicking — it's deterministic and
needs no input injection:

```bash
qs ipc -c crux show                              # list targets
qs ipc -c crux call controlCenter_DP-2 toggle    # per-screen target
qs ipc -c crux call launcher toggle              # global target
```

Full-screen NPanelWindow surfaces (launcher, settings, wallpaper browser)
take keyboard focus while open. Crux is the live desktop: if the user is
typing elsewhere, the launcher eats their keystrokes. Capture those only
when the user isn't mid-input, and close them right away.

Per-screen surfaces register `<name>_<output>` targets; use the one for the
output you're capturing. Avoid IPC functions named `show` (CLI collision —
see [`popups.md`](popups.md)). Give the open animation time to finish before capturing
(durations are in `Commons/Tokens.qml` §7); capture too early and you're
reviewing a mid-slide frame.

For keyboard interaction, use `ydotool` (`ydotoold` runs as a user
service; `wtype` is not installed). It takes evdev keycodes from
`/usr/include/linux/input-event-codes.h`, `<code>:1` press / `<code>:0`
release:

```bash
ydotool key 106:1 106:0      # Right
ydotool key 28:1 28:0        # Enter
ydotool key 1:1 1:0          # Escape
ydotool type 'firefox'       # text into a focused search field
```

Confirm the resulting state change (`Settings.data` in
`~/.config/crux/settings.json`, a launched process, a layer appearing in
`hyprctl layers -j`), not just the pixels. Pointer-only interactions
(drag-reorder, hover) can be driven with `ydotool mousemove`/`click`, but
treat those results cautiously and ask the user to check by hand if it
matters.

**Never drive the lock screen or polkit dialog with real auth input** —
failed attempts count against `pam_faillock` and lock the account (see
[`privileged.md`](privileged.md)). Verify those by their layer namespace appearing in
`hyprctl layers -j`.

## Animations and transitions

No video recording. Check an animation by its end states: capture once
before triggering, then again after the duration in `Commons/Tokens.qml` §7
has elapsed. If a mid-transition problem is suspected (overshoot, clipping
during collapse), take one or two timed stills partway through
(`sleep 0.1; grim ...`) — stills only, never a stitched video.

Blinking elements (carets, cursors) can be in their off phase in any single
still — a clean screenshot isn't proof something isn't drawn (`docs/design-notes.md`, the
`cursorDelegate` story). Take a few stills a fraction of a second apart.

## Cleanup

Close anything you opened (`... toggle` again, or `ydotool key 1:1 1:0`)
so the user's desktop is left as you found it. Kill only processes you
started, by PID — never broad `pkill qs`, which takes down the user's live
shell. Revert any temporary debug tinting before committing.
