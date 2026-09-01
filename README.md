# crux

A [QuickShell](https://quickshell.org) desktop shell for Hyprland, built
from scratch because rounded corners felt like a personal attack.

![crux running on a vertical bar](.github/screenshot.png)

## What is this

My own daily-driver desktop shell. Bar, lock screen, notifications,
on-screen displays, a settings panel with 21 tabs and a search box, a
wallpaper-driven Material You theming pipeline, and every corner cut at a
45° angle on principle. No forked UI kit, no plugin marketplace, no
telemetry phoning home to tell someone I changed my wallpaper again.

## Features

- **Bar** — top/bottom/left/right, floating or flush, drag-to-reorder
  widgets, per-monitor overrides, and a "Comfortable"/"Compact" density
  preset for people who can't decide
- **Wallpaper theming** — pick a wallpaper, matugen derives the entire
  color scheme from it, optionally retheming Hyprland, kitty, GTK, Qt,
  yazi, btop, starship, and Discord to match
- **Lock screen** — PAM-backed, a matching SDDM login theme, and a lockout
  timer for anyone who forgot their own password too many times
- **Notifications, OSD, Control Center, launcher, clipboard history** —
  the usual suspects, all real, none of them stubbed out
- **A settings panel with a search box** — because "which of these 21
  tabs was the toggle in" is a real problem once you build enough of them
- **A Wallhaven browser** built in, in case you'd rather not leave the
  house for a new wallpaper

## Requirements

- [Hyprland](https://hyprland.org) + [Quickshell](https://quickshell.org)
- `matugen`, `brightnessctl`, `wlsunset`, `cliphist`, `wl-clipboard`,
  `playerctl`, `networkmanager`, `bluez`, `python`, `git`

Optional, if you want the wallpaper pipeline to reach further: `kitty`,
`gtk3`/`gtk4`, `qt6ct`, `yazi`, `btop`, `starship`, `vesktop`, `sddm`.
Nothing breaks if you don't have them — those templates just sit there
unused until you flip them on.

## Install

```
git clone <this repo> ~/.config/quickshell/crux
qs -c crux
```

Point Hyprland's `exec-once` at `qs -c crux` to make it your actual login
shell instead of a thing you run once to see if it still boots.

An AUR package (`crux-shell-git`) lives in [`packaging/`](./packaging) —
installs to `/etc/xdg/quickshell/crux` so `qs -c crux` works for any user
on the system. See its README for the current state of that effort.

## Configuration

Everything's in the settings panel (bar icon, or `qs -c crux ipc call
settings toggle`). Settings persist to `~/.config/crux/settings.json` —
plain JSON, no schema migrations to fear, no wizard to click through
first.

## Design

Two opposite corners chamfered, never rounded — the one rule that applies
to almost everything on screen. Colors come from Material You roles
regenerated from your wallpaper, not a hardcoded palette. If something
looks hardcoded anyway, it's a bug.

## License

Personal project, no license file yet, which legally means "all rights
reserved, ask first." Take the ideas, don't take the repo verbatim and
call it yours.

---

<sub>made with ~~Claude~~ love</sub>
