# Task Guides

Deeper instructions for specific kinds of work live in `agents/skills/`. Read the matching guide before starting:

- [`agents/skills/dev-loop.md`](agents/skills/dev-loop.md) - restarting crux and reading the boot log, before any change goes live
- [`agents/skills/bar-widgets.md`](agents/skills/bar-widgets.md) - adding or changing widgets under `Modules/Bar/`
- [`agents/skills/popups.md`](agents/skills/popups.md) - popups, panels, PopupHost cards and their IPC targets
- [`agents/skills/settings.md`](agents/skills/settings.md) - new settings, schema files and settings-panel tabs
- [`agents/skills/porting.md`](agents/skills/porting.md) - bringing a feature over from Omarchy or noctalia-shell
- [`agents/skills/privileged.md`](agents/skills/privileged.md) - scripts that need root, the polkit agent, the lock screen
- [`agents/skills/visual-verification.md`](agents/skills/visual-verification.md) - checking any change with a visual effect in the running shell

# Documentation Layout

Two documentation trees, split by genre:

- `agents/skills/` - task procedure ("do this when doing X")
- `docs/` - reference on how crux is shaped; skills link here for depth
  - [`docs/architecture.md`](docs/architecture.md) - directory layout and layering rules
  - [`docs/look-and-feel.md`](docs/look-and-feel.md) - tokens, motion, depth, theming, the reverted Direction D
  - [`docs/qml-gotchas.md`](docs/qml-gotchas.md) - Qt/QuickShell traps that have already cost a debugging session
  - [`docs/hyprland.md`](docs/hyprland.md) - this machine's Lua Hyprland config and how crux talks to it
  - [`docs/design-notes.md`](docs/design-notes.md) - the why behind individual decisions, one section per topic

`README.md` is for people installing crux; never put codebase internals there.

# Crux Is the Live Desktop

- Crux is the daily driver on this machine (`~/.config/hypr/exec.lua` runs `qs -c crux`), on both user accounts.
- Restarting it restarts the real desktop. A failed relaunch leaves the user with no bar, notifications or lock screen.
- Make one confirmed change at a time. Boot-test after each one, and keep each as its own revertible commit.

# Style

- Two spaces for indentation, no tabs
- QML comments are terse: one line, only when something is genuinely non-obvious. Rationale goes in `docs/design-notes.md`
- No hardcoded hex colors, font families, durations or easings at call sites. Use `Colors`, `Tokens` and `FontService` (only `LockScreen.qml` and `PolkitAgent.qml` are exempt)
- No `MouseArea` in bar widgets. Use `TapHandler`/`HoverHandler` (see [`bar-widgets.md`](agents/skills/bar-widgets.md))
- Don't name a singleton after a QtQuick type (`Color` was shadowed by Qt 6.12; it's `Colors` now)
- In markdown, write full lines. Break only at headings and list items
- Shell scripts in `bin/` use `#!/bin/bash`, `[[ ]]` for string/file tests and `(( ))` for numeric tests

# Command Naming

CLI helpers live in `bin/` and all start with `crux-`. Scripts ported from Omarchy keep their name with `omarchy-` swapped for `crux-` (`crux-network-status`, `crux-bluetooth-device`).

# Runtime Environment

- Upstream `quickshell` from Arch `extra`, not the abandoned `noctalia-qs` fork. Don't use fork-only API (`PwAudioSpectrum`, `CornerState`, `Quickshell.Niri`)
- Settings: `~/.config/crux/settings.json`, through `Commons/Settings.qml`
- Hyprland runs a Lua config: `Hyprland.dispatch("workspace N")` silently fails. See [`docs/hyprland.md`](docs/hyprland.md)

# Background Work

- React to events (Hyprland raw events, Pipewire, UPower, `FileView` watches) instead of polling with a `Timer`. Polling is the last resort
- Anything that owns a process, DBus connection or hardware state is a singleton in `Services/`, not a widget. Widgets exist once per monitor

# Git

- Repo is `~/.config/quickshell/crux`, branch `main`. Remotes are `origin` (self-hosted) and `github` (`teezlabs/crux-shell`)
- Commits are atomic and use a lowercase imperative subject that says what changes for the user (`add a do-not-disturb quick toggle`)
- `packaging/PKGBUILD` is the AUR source of truth. `.github/workflows/aur-publish.yml` pushes it on changes to `main`

# Tests

There is no automated suite. The checks are:

1. A boot log that ends at `Configuration Loaded` with no `WARN` lines ([`dev-loop.md`](agents/skills/dev-loop.md))
2. Visual verification in the running shell for anything visible ([`visual-verification.md`](agents/skills/visual-verification.md))
