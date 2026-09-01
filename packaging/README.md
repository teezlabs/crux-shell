# Packaging

`PKGBUILD` builds `crux-shell-git`, installing crux to
`/etc/xdg/quickshell/crux` so `qs -c crux` works for any user on the
system (Quickshell resolves named configs from `$XDG_CONFIG_DIRS`, which
defaults to including `/etc/xdg`).

## Before this can go on the AUR

The `source` URL points at this repo's Forgejo remote, which only
resolves over Tailscale right now (private IP, SSH-only, auth-gated).
Neither `makepkg` on someone else's machine nor the AUR's own build
checks can reach it. Pick one:

- Expose the Forgejo instance's git-http(s) endpoint publicly (read-only
  access to just this repo is enough), and switch `source` to an
  `https://` URL.
- Mirror the repo to somewhere already public (GitHub, GitLab, sr.ht) and
  point `source` there instead.

Either way, once `source` is publicly fetchable:

```
cd packaging
makepkg --printsrcinfo > .SRCINFO   # regenerate after any PKGBUILD edit
makepkg -si                          # build + install locally, sanity check
```

Then follow the AUR's own new-package flow: clone
`ssh://aur@aur.archlinux.org/crux-shell-git.git` (empty repo, AUR creates
it as soon as you push once you're an AUR account holder with your SSH
key on file), copy `PKGBUILD` + `.SRCINFO` in, commit, push.

## Local testing without any of that

If you're building on a machine that can already reach the Forgejo
instance (on the tailnet, with the SSH key set up — same as this repo's
own `git push`), `makepkg -si` from `packaging/` works today, `source`
URL and all.

## Not included here

The SDDM login theme (`/usr/share/sddm/themes/crux/`) is a separate,
more invasive system-wide install (touches `/etc/sddm.conf.d/`) — it's
listed as an `optdepends` hint on `sddm` but this package doesn't
install or activate it. See the crux skill's `notes.md`/`SKILL.md` for
the manual steps if you want it packaged too later.
