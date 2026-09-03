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

## Publishing (automated)

`PKGBUILD` here is the source of truth. `.github/workflows/aur-publish.yml`
mirrors it to `ssh://aur@aur.archlinux.org/crux-shell-git.git` on every push
to `main` that touches it, regenerating `.SRCINFO` with a real `makepkg` in
an Arch container rather than trusting whatever was committed next to it.

Setup, once:

1. Add `~/.ssh/aur-ci-crux.pub` to the AUR account
   (https://aur.archlinux.org/account/ -> SSH Public Key; keep any existing
   key, the field takes several one per line).
2. `gh secret set AUR_SSH_KEY --repo teezlabs/crux-shell < ~/.ssh/aur-ci-crux`

It's a dedicated key, not the personal one used for normal AUR pushes, so
revoking CI access doesn't cost you your own.

Manual push, if CI is unavailable: clone the AUR repo, copy `PKGBUILD` +
`.SRCINFO` in, commit, push.

**Why this is automated:** the two copies drifted once already. The AUR held
an older `package()` while `source=` still pulled current code, so an
installed crux was assembled by a stale recipe and died at startup with
`module "qs.Widgets" is not installed` — while reporting a version string
from the commit that contained the fix.

## Not included here

The SDDM login theme (`/usr/share/sddm/themes/crux/`) is a separate,
more invasive system-wide install (touches `/etc/sddm.conf.d/`) — it's
listed as an `optdepends` hint on `sddm` but this package doesn't
install or activate it. See the crux skill's `notes.md`/`SKILL.md` for
the manual steps if you want it packaged too later.
