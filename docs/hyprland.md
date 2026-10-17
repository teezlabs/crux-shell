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
- `ws.active` is per monitor (several can be true). `ws.focused` is the single workspace with keyboard focus. Crux highlights `focused`

## Config gotchas

- `hl.env(...)` applies only at compositor startup, not on `hyprctl reload`
- `mod("", "KEY")` is SUPER+KEY. Check `mod()` at the top of `keybinds.lua` for other modifiers
- Use `border_color` in window rules, not `col`/`bordercolor`
- Layer blur matches namespaces by literal string. New crux namespaces need adding to `windowrules.lua`

## Monitors and capture

- Two outputs: `DP-1` (rotated portrait) and `DP-2`. `hyprctl monitors -j` lists them
- Two Hyprland instances can run at once (two users), but only one holds DRM master. `grim` against the other one hangs. Check `cat /sys/class/tty/tty0/active` first
