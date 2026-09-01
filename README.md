<div align="center">

# crux

<img src=".github/screenshot.png" alt="crux running on a vertical bar" width="800">

<h4>Built from scratch. No forked UI kit, no plugin marketplace, no telemetry.</h4>

![GitHub Repo stars](https://img.shields.io/github/stars/teezlabs/crux-shell?style=for-the-badge&logo=github&color=pink)
![GitHub commit activity](https://img.shields.io/github/commit-activity/t/teezlabs/crux-shell?style=for-the-badge&logo=github&color=lightgreen) <br>
![Static Badge](https://img.shields.io/badge/hypr-crux-lightblue?style=for-the-badge)

</div>

> [!WARNING]
> This is my personal daily driver. It changes under me without warning, and every corner gets chamfered whether you like it or not.

> [!TIP]
> Everything's configurable from the settings panel — search box included, because 21 tabs is a lot to remember.

## What it does

Bar, lock screen, notifications, OSD, Control Center, launcher, clipboard
history, and a wallpaper-driven Material You theming pipeline that can
retheme Hyprland, kitty, GTK, Qt, yazi, btop, starship, and Discord to
match whatever's on screen.

## Dependencies

> [Hyprland](https://hyprland.org)<br>
> [Quickshell](https://quickshell.org)<br>
> `matugen`, `brightnessctl`, `wlsunset`, `cliphist`, `wl-clipboard`,
> `playerctl`, `networkmanager`, `bluez`

## Plugins

> Local-folder only — drop a `manifest.json` + `Widget.qml` in
> `~/.config/crux/plugins/<name>/`. No marketplace, no network.

## Install

**Arch (AUR):**

```
yay -S crux-shell-git
qs -c crux
```

**Manual:**

```
git clone https://github.com/teezlabs/crux-shell ~/.config/quickshell/crux
qs -c crux
```

Point Hyprland's `exec-once` at `qs -c crux` to make it your real login
shell. `crux-shell-git` is a VCS package — track upstream `HEAD` with
`yay -S crux-shell-git --devel`.

## Configuration

Bar icon, or `qs -c crux ipc call settings toggle`. Persists to
`~/.config/crux/settings.json` — plain JSON, no wizard.

<div align="center">

<sub>made with ~~Claude~~ love</sub>

</div>
