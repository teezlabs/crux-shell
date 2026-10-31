# Look and Feel

Crux follows the spec in `docs/Quickshell Hyprland Shell v2.pdf`. `Commons/Tokens.qml` holds the numbers, with sections that match the spec: §1 panel opacity, §2 type, §3 spacing, §4 geometry and borders, §5 segmented meters, §6.1 bar geometry, §7 motion, §8 elevation. `Commons/Colors.qml` holds the semantic colors.

## Current direction

- Outlined panels, Control Center circles, round sliders and ring gauges
- Every corner is a chamfer. No radii anywhere. `ConcaveCorner` is a straight 45° cut, not an arc
- Workspaces: a filled cell marks the focused workspace; the accent edge mark and accent number mark the workspace each monitor is showing, so the unfocused monitor still reads
- **Direction D was reverted on 2026-10-17** (fill-only, no outlines, cut squares, segmented meters). Commit `6623f0b` undid it. Don't reapply D-style changes unless asked

## Bar surface

The bar strip and the drawers joined to it fill with `Colors.barSurface`: `surface` with 8% of `primary` mixed in. Schemes like rainbow and neutral generate pure-grey neutrals, which left the strip near-black; the tint carries the theme's hue into the bar whatever the scheme.

## State colors

Bar modules (and anything that copies them) use one meaning per color:

- **On / active:** tint the icon `Colors.primary`. No box
- **Needs attention:** tint the icon `Colors.tertiary` and set the button's `attention`, which draws a tertiary box. Reserve this for states the user should notice (usage near a limit, a forced mode, a degraded profile, keep-awake left on)
- **Critical, muted or destructive:** `Colors.error`. The power button's faint `error` outline is the one permanent accent
- **Off / unavailable:** `Colors.surfaceTextMuted`, or `Colors.disabledText` when the feature is unusable

## Motion

- Durations and easings come from Tokens §7. Never type one at a call site
- Color changes ease shell-wide because the `Behavior` lives in `Chamfer`, `NText` and `NIcon`. A retheme cross-fades the desktop. Set `animateColor: false` for anything that must track a value instantly
- `Widgets/NPressFeedback.qml` is the press response. Point `scaleTarget` at the control and call `trigger()` from the `TapHandler`. `NButton` and `BarIconButton` already include it

## Depth

- `Chamfer` takes `shadow` and `rimLight`, both off by default, tiered in Tokens §8
- The shadow is masked out under the shape, because panels are translucent
- Shadows are cast by the chamfered shape itself, never a rectangle behind it, so a cut corner still reads as cut. Three tiers only: the shell is flat by design, and depth says "this floats above that"
- The shadow is hard black, not tinted. Over a near-black desktop a tinted shadow reads as a glow
- On dark themes a shadow alone barely shows (about 3/255 luminance). The rim light is what reads as elevation
- Floating surfaces use both. Bar modules and `SlideCard` use the rim only, since there's no room for a shadow to fall

## Theming

All native, no external daemon.

1. A wallpaper is picked in the settings grid or the Wallhaven browser (`Services/Wallhaven.qml`)
2. That sets `Settings.data.wallpaper.path` through the `wallpaper` IPC target in `shell.qml`
3. `Services/Matugen.qml` runs `matugen --json` and writes the result into `Settings.data.theme`
4. Templates in `bin/theme-templates/` push the palette into Hyprland, kitty, GTK, Qt, yazi, btop, starship and Discord (Vesktop and BetterDiscord share `vesktop.css`, whose META header BetterDiscord needs to list the theme)

`skwd-daemon` and `~/.cache/skwd-wall/` were removed on purpose. Don't bring them back.

## Icons and fonts

- Recolor symbolic icons. Leave app icons alone
- Don't trust emoji or system Nerd Font glyphs here (`monospace` is Noto Sans Mono). Draw shapes, or load a bundled font from `Assets/Fonts/`
