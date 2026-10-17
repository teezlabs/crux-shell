# Hyprland

This machine runs Hyprland with a Lua config. Crux talks to it through Quickshell's `Hyprland` module and `hyprctl`.

## Config files

```
~/.config/hypr/
├── hyprland.lua       # monitors, env vars, exec-once, requires the rest
├── keybinds.lua       # raw hl.bind(mod(...), hl.dsp.exec_cmd(...))
├── exec.lua           # autostart: qs -c crux, qs -c overview
├── windowrules.lua    # window and layer rules, including blur by namespace
├── animations.lua
├── plugins.lua        # hyprpm plugins (scrolloverview)
└── active-shell       # names the shell autostart launches
```

## Dispatching

Legacy verb syntax fails. `Hyprland.dispatch("workspace N")` errors silently. Use the Lua form:

```qml
Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + id + " })"])
```

```bash
hyprctl dispatch "workspace 3"                     # error: ')' expected
hyprctl dispatch "hl.dsp.focus({ workspace = 3 })" # ok
```

Check any ported script that calls `hyprctl dispatch` for this.

## Workspace state

- `Hyprland.workspaces.onValuesChanged` fires only when workspaces are created or destroyed, not on a focus switch. Refresh from `Connections { target: Hyprland; function onRawEvent(event) {...} }`
- `ws.active` is per monitor (several can be true). `ws.focused` is the single workspace with keyboard focus. Crux fills the `focused` cell and edge-marks each monitor's `active` one

## Config gotchas

- `hl.env(...)` applies only at compositor startup, not on `hyprctl reload`
- `mod("", "KEY")` is SUPER+KEY. Check `mod()` at the top of `keybinds.lua` for other modifiers
- Use `border_color` in window rules, not `col`/`bordercolor`
- Layer blur matches namespaces by literal string. New crux namespaces need adding to `windowrules.lua`

## Monitors and capture

- Two outputs: `DP-1` (rotated portrait) and `DP-2`. `hyprctl monitors -j` lists them
- Two Hyprland instances can run at once (two users), but only one holds DRM master. `grim` against the other one hangs. Check `cat /sys/class/tty/tty0/active` first

## Window corner shaders

`Assets/hypr-shaders/` overrides three of Hyprland's built-in shaders so windows get crux's per-corner chamfers instead of a symmetric superellipse.

- `rounding.glsl` clips window contents, `border.glsl` draws the border along the same outline, and `quad.frag` exists only to tell `rounding.glsl` that rects have no texcoord
- `Services/WindowCorners.qml` copies them to `~/.cache/crux/hypr-shaders` with `CRUX_DEFAULT_MASK` set from Appearance → General → Window corners (`Settings.data.windowCorners`), then runs `hyprctl reloadshaders` on that directory at boot and on every change. Turning the setting off reloads the stock shaders. They survive `hyprctl reload`, so they only need loading once per session. `hyprctl reloadshaders` with no path goes back to the stock shaders. The directory is passed in at runtime, so a broken override never affects compositor startup
- Never copy the files into `~/.config/hypr/shaders/`. Hyprland loads that directory at startup, and a shader that fails there takes the compositor down with it
- The size of the cut is `decoration:rounding`. `rounding = 30` gives a cut of about 14px
- The corners come from `rounding_power`. Any value outside `[3, 4)` uses the mask chosen in settings. A window rule can set `rounding_power = 3 + mask / 16` with bits TL=1, TR=2, BR=4, BL=8 (top-left and bottom-right is `3 + 5/16 = 3.3125`)
- Stock `shadow.glsl` and `inner_glow.glsl` aren't overridden yet. With either enabled, they draw a symmetric chamfer
- After a Hyprland update, diff `/usr/include/hyprland/src/render/shaders/{rounding.glsl,border.glsl,quad.frag}.inc` against these files. `getBorder`'s signature has to match `border.frag` exactly

Testing a change:

- Swapping shaders doesn't trigger a redraw, so a `grim` capture straight after a reload shows the old frame. Set `debug:damage_tracking` to 0 while capturing (`hyprctl eval 'hl.config({ debug = { damage_tracking = 0 } })'`), then back to 2
- `glslangValidator` can compile the frags offline once the `#include`s are inlined
