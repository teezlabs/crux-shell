# Porting From Omarchy or noctalia

Read this before bringing a feature over from another shell.

## Get the source

- **Omarchy:** fetch it fresh, `git clone --depth 1 --branch quattro https://github.com/basecamp/omarchy`. Panels live in `shell/plugins/panels/<name>/{Panel.qml,Model.js,manifest.json}`, bar widgets in `shell/plugins/bar/widgets/`, CLI helpers in `bin/omarchy-*`
- **noctalia-shell:** `~/dev/noctalia-shell`
- `~/dev/omarchy`, `~/dev/aurora-plugins` and `aurora-switch-shell` no longer exist. Don't search the disk for them

## What to copy and what to rebuild

- **Copy verbatim:** `Model.js` files. They're plain JS (parsing, sorting, formatting) with no framework ties. `NetworkModel.js` and `BluetoothModel.js` came over this way
- **Copy and rename:** `bin/omarchy-*` scripts that don't call other Omarchy scripts. Check with `grep -n "omarchy-\|source " <script>` first, then rename to `crux-*`
- **Rebuild:** `Panel.qml` and widget files. They're built on Omarchy's `Ui` kit and plugin framework. Read them for the data flow (which `Quickshell.*` service, which calls, in what order), then rebuild the UI on crux's `Widgets/` kit
- **Never import** Omarchy's `shell/Ui/` or `shell/Commons/` wholesale

## Fitting it into crux

- Body goes in a popup ([`popups.md`](popups.md)), icon goes on the bar ([`bar-widgets.md`](bar-widgets.md)), hardware goes in `Services/`
- Swap the source's colors, sizes and durations for `Colors` and `Tokens`
- Replace legacy `hyprctl dispatch` verbs with Lua `hl.dsp.*` calls ([`docs/hyprland.md`](../../docs/hyprland.md))
- Record why you diverged from the source in [`docs/design-notes.md`](../../docs/design-notes.md)
