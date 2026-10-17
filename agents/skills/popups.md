# Popups

Read this before adding or changing a popup, panel or full-screen surface.

## Pick the mechanism by shape

| Shape | Use | Where |
| --- | --- | --- |
| Grows out of the bar edge | `SlideCard` in `PopupHost` | `Modules/Popups/PopupHost.qml`, body in `Modules/Popups/Contents/<X>PopupContent.qml` |
| Centered or scrimmed, needs keyboard focus | `NPanelWindow` | `Widgets/NPanelWindow.qml` |

`NotificationsWindow` is neither: a corner-anchored toast stack with no registration and no Escape, on purpose. Don't "fix" it.

## Adding a bar-flush popup

1. Write the body as `Contents/<X>PopupContent.qml`. Pure logic (parsing, sorting) goes in a sibling `<X>Model.js`
2. Add a `SlideCard` block and a `PopupIpc` line in `PopupHost.qml`
3. Add the card to PopupHost's `cards` array **and** to its `anyOpen` chain. Extend the `||` chain by hand. Don't rewrite it as `cards.some(...)`: it drives the input mask, and a wrong mask once locked the whole desktop
4. Add the screen-agnostic alias in `PopupAliases.qml` (it lives once in `shell.qml`, never per monitor)
5. Give it the shared `PopupHeader` and `PopupRowBackground` so it matches the others

## Adding a full-screen panel

- Set `popupName`, and `surfaceNamespace` if the layer name isn't `"crux-" + popupName`
- `NPanelWindow` already supplies `PopupRegistration`, the per-screen IPC target, the layer-shell block, Escape and click-outside
- Keep it `visible`-toggled. An always-mapped surface must set an explicit empty `Region {}` mask, or it swallows every click on the screen

## Blur

Hyprland's blur rule in `~/.config/hypr/windowrules.lua` matches layer namespaces by literal string. A new or renamed namespace has to be added there, or the surface renders unblurred.

## How popups get opened

- **From inside crux:** call through `Commons/Popups.qml`, the in-process registry keyed by name + screen. Never shell out to `qs ipc` from QML
- **From outside (keybinds, scripts):** IPC. Each popup has a per-screen target `<name>_<output>` and a plain `<name>` alias that resolves the focused monitor at call time
- Every surface implements `open()`, `close()`, `toggle()`, and optionally `openAt(x, y)`
- Never name an IPC function `show`: `qs ipc -c crux call <target> show` prints the function list instead of calling it

```bash
qs ipc -c crux call launcher toggle
qs ipc -c crux call controlCenter_DP-2 toggle
```

Known gap: notifications animate in but not out, because a `Repeater` destroys its delegate immediately. Fixing it needs a `ListView` with remove transitions.
