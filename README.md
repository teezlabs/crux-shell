# crux

A [QuickShell](https://quickshell.org) desktop shell for Hyprland, built
from scratch because rounded corners felt like a personal attack.

![crux running on a vertical bar](.github/screenshot.png)

Bar, lock screen, notifications, OSD, a settings panel with 21 tabs and a
search box, and a wallpaper-driven Material You theming pipeline that can
retheme Hyprland, kitty, GTK, Qt, yazi, btop, starship, and Discord to
match. No forked UI kit, no plugin marketplace, no telemetry.

## Requirements

[Hyprland](https://hyprland.org) + [Quickshell](https://quickshell.org),
plus `matugen`, `brightnessctl`, `wlsunset`, `cliphist`, `wl-clipboard`,
`playerctl`, `networkmanager`, `bluez`, `python`, `git`.

## Install

```
git clone <this repo> ~/.config/quickshell/crux
qs -c crux
```

Point Hyprland's `exec-once` at `qs -c crux` to make it your real login
shell. An AUR package lives in [`packaging/`](./packaging).

## Configuration

Bar icon, or `qs -c crux ipc call settings toggle`. Persists to
`~/.config/crux/settings.json` — plain JSON, no wizard.

---

<sub>made with ~~Claude~~ love</sub>
