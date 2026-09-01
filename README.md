# crux

A personal [QuickShell](https://quickshell.org) desktop shell for Hyprland,
built from scratch rather than forked, and the daily driver on this
machine. Built one confirmed, boot-tested step at a time; see
[`ROADMAP.md`](./ROADMAP.md) for what's built vs. still open.

## Requirements

- [Hyprland](https://hyprland.org) + [Quickshell](https://quickshell.org)
- `matugen` — wallpaper-driven Material You theming
- `brightnessctl` — backlight control
- `wlsunset` — night light / blue-light filter
- `nmcli`, PipeWire/WirePlumber, bluez — network, audio, bluetooth (via
  Quickshell's built-in services where possible)
- `cliphist`, `wl-clipboard` — clipboard history
- `playerctl` — media control
- `grim` — screenshots (settings-panel verification, not a runtime dep of
  the shell itself)
- `git` — read live inside the About tab (commit hash/date)
- `python3` — a couple of helper scripts under `bin/`

## Running it

```
qs -c crux
```

To make it the actual login shell, point Hyprland's `exec-once` at
`qs -c crux` instead of whatever shell currently starts (see
`~/.config/hypr/exec.lua` on this machine).

### Dev loop

QuickShell's instance registry doesn't reliably survive a kill-then-relaunch
chained into one shell command — do it as separate steps:

```bash
pkill -f "qs -c crux"
sleep 1
rm -f /tmp/crux-boot.log
nohup qs -c crux > /tmp/crux-boot.log 2>&1 & disown
sleep 3
cat /tmp/crux-boot.log   # clean boot ends at "Configuration Loaded", no WARN lines
```

## Layout

```
shell.qml                 # entry point — wallpaper, bar, OSD, lock screen, IPC targets
Commons/                  # singletons: Settings, Color, Style, Tokens, Matugen, Hooks, ...
Modules/
  Bar/                    # the bar itself — sections, widget registry/loader, popups
    Widgets/              #   one file per bar widget (Clock, Sound, Wifi, ControlCenter, ...)
    Extras/                #   popup windows, shared chrome (Chamfer, BarModule, BarIconButton)
  SettingsPanel/          # the settings window — one Tab.qml (+ SubTab.qml) per settings section
  LockScreen/              # PAM-backed lock screen
  OSD/                     # volume/brightness on-screen displays, toast overlay
  Background/              # wallpaper + shader transitions, desktop widgets
  Polkit/                  # polkit auth agent UI
  Tooltip/                 # shared tooltip overlay
Assets/
  ColorSchemes/            # built-in palette presets
  Shaders/                 # compiled .qsb wallpaper-transition shaders
bin/                       # standalone helper scripts (see header comment in each for what/why)
```

Settings are JSON-backed at `~/.config/crux/settings.json` via
`Commons/Settings.qml` — no telemetry, setup wizard, or plugin marketplace
by design.

## Settings panel

18 top-level tabs (General, Bar, Appearance, Audio, Hue, Display, System
Monitor, Wallpaper, Desktop Widgets, OSD, Session Menu, Lock Screen, Idle,
Notifications, Peripherals, Hooks, Plugins, About), most split into subtabs.
The sidebar has a fuzzy-search box that jumps straight to a matching
setting's tab and subtab.

## Design notes

Two-opposite-corner chamfered corners (`Chamfer.qml`) instead of rounded
corners are the shell's signature look, driven by Material You colors
(`Color.qml`) generated live from the wallpaper via matugen. Design
rationale that doesn't belong in code comments — port decisions, layout
formulas, revision history on things that changed more than once — lives in
the `crux` Claude Code skill's `notes.md`, not scattered through the QML.
