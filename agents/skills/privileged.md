# Privileged Work

Read this before writing a script that needs root, or touching the polkit agent or lock screen.

## Scripts that need root

`bin/crux-dns` is the pattern:

- The script names its own install path (`PACKAGED_PATH=/usr/bin/crux-dns`)
- It escalates through `sudo -n` (passwordless grant), then interactive `sudo` (when there's a terminal), then `pkexec`
- `packaging/crux-dns.sudoers` grants passwordless sudo for the exact non-interactive commands only. `Custom` is left out on purpose because it needs a terminal
- Interactive flows spawn `kitty`, the terminal set in `~/.config/hypr/keybinds.lua`

**Always ask the user before writing to `/usr/bin` or `/etc/sudoers.d`.**

## Never test real authentication

The PAM stack uses `pam_faillock` (3 failures, 10-minute lock). Three non-interactive `pkexec true` calls once locked the user out of sudo, pkexec and screen unlock.

- Don't run `pkexec`, or anything that asks for a password, without a real password
- Don't drive the lock screen or polkit dialog with fake input
- To check the polkit agent, watch for the `crux-polkit` namespace in `hyprctl layers -j`
- To check for lockouts, use `faillock --user $USER` and `journalctl -b | grep -i polkit`
- Never restart crux while the session is locked. `misc:allow_session_lock_restore` is off, so a dead lock client leaves Hyprland's red lockscreen-died screen and no way back in from the desk. `grim` still captures the lock screen while locked, so screenshots over SSH are safe
