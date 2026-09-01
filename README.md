<div align="center">

# crux

<img src=".github/screenshot.png" alt="crux running on a vertical bar" width="800">

<h4>Built from scratch. No forked UI kit, no plugin marketplace, no telemetry.</h4>

![GitHub Repo stars](https://img.shields.io/github/stars/teezlabs/crux-shell?style=for-the-badge&logo=github&color=pink)
![GitHub commit activity](https://img.shields.io/github/commit-activity/t/teezlabs/crux-shell?style=for-the-badge&logo=github&color=lightgreen)
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

<table><tr><td>
<code>D</code><br><code>E</code><br><code>T</code><br><code>A</code><br><code>I</code><br><code>L</code><br><code>S</code><br></td><td><table>
    <tr><td>OS</td><td>Arch</td></tr>
    <tr><td>WM</td><td>Hyprland</td></tr>
    <tr><td>Shell</td><td>crux (QuickShell)</td></tr>
    <tr><td>Terminal</td><td>Kitty</td></tr>
 </table>
</td></tr></table>

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

<div align="center">

<sub>made with ~~Claude~~ love</sub>

</div>
