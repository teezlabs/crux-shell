---
name: crux
description: 'REQUIRED for working on "crux shell" — the user''s own from-scratch QuickShell desktop at ~/.config/quickshell/crux, their daily driver. Use when editing anything under ~/.config/quickshell/crux, adding or fixing bar widgets, popups or settings, porting features from Omarchy (basecamp/omarchy) or noctalia-shell into crux, or touching ~/.config/hypr/ in service of crux. Triggers: crux shell, crux bar, QuickShell widget, bar widget registry, PopupHost, Hyprland Lua config, omarchy source port, matugen theming.'
---

# Crux

Crux is the user's own QuickShell desktop shell, and the one their desktop runs on.

- **Repo:** `~/.config/quickshell/crux` (branch `main`)
- **Launch:** `qs -c crux`
- **Settings:** `~/.config/crux/settings.json`

## Start here

Read `~/.config/quickshell/crux/AGENTS.md` first. It lists the task guides in `agents/skills/` and the reference pages in `docs/`. Open the guide that matches the task before you change anything.

## Rules that always apply

1. **Crux is the live desktop.** A relaunch restarts the user's real bar, notifications and lock screen. Follow `agents/skills/dev-loop.md` exactly, one step per tool call
2. **One confirmed change at a time.** Boot-test after each, one commit each, so any step can be reverted
3. **A clean boot log has no `WARN` lines.** Any warning is a bug to fix first
4. **Visual changes need a screenshot check.** See `agents/skills/visual-verification.md`
5. **Never test real authentication.** Failed `pkexec`/lock-screen attempts trip `pam_faillock` and lock the account. See `agents/skills/privileged.md`
6. **Ask before writing to `/usr/bin`, `/etc` or `/etc/sudoers.d`**

## Keeping the docs current

- When you learn something non-obvious, write it into the repo's `docs/` or `agents/skills/`, not into this skill
- When a doc turns out to be wrong, fix it in the same commit as the code
