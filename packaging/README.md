# Packaging

`PKGBUILD` builds `crux-shell-git`, installing crux to
`/etc/xdg/quickshell/crux` so `qs -c crux` works for any user on the
system (Quickshell resolves named configs from `$XDG_CONFIG_DIRS`, which
defaults to including `/etc/xdg`).

## Ready for the AUR

`source` points at `https://github.com/teezlabs/crux-shell` (public, no
auth) — `makepkg` resolves it from anywhere now, including the AUR's own
build checks.

```
cd packaging
makepkg --printsrcinfo > .SRCINFO   # regenerate after any PKGBUILD edit
makepkg -si                          # build + install locally, sanity check
```

To actually submit: clone `ssh://aur@aur.archlinux.org/crux-shell-git.git`
(empty repo, AUR creates it as soon as you push once you're an AUR
account holder with your SSH key on file), copy `PKGBUILD` + `.SRCINFO`
in, commit, push.

## Not included here

The SDDM login theme (`/usr/share/sddm/themes/crux/`) is a separate,
more invasive system-wide install (touches `/etc/sddm.conf.d/`) — it's
listed as an `optdepends` hint on `sddm` but this package doesn't
install or activate it. See the crux skill's `notes.md`/`SKILL.md` for
the manual steps if you want it packaged too later.
