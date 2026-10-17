# QML Gotchas

Each of these has already cost a debugging session on this box (Qt 6.11–6.12, upstream quickshell). None of them produce a warning. The QML is valid and it silently misbehaves. Fuller stories live in [`design-notes.md`](design-notes.md).

## Input

- **`MouseArea` under a passive `TapHandler` gets nothing through.** With a `MouseArea` anywhere below, the ancestor `TapHandler` sees zero events. Use pointer handlers throughout bar widgets
- **An always-mapped layer surface captures input everywhere.** `enabled: false` on a `MouseArea` doesn't change the Wayland input region. Use `mask: anyOpen ? null : emptyMask` with `Region { id: emptyMask }`. Skipping it locks the whole desktop
- **`TextInput.cursorVisible: false` doesn't hide the cursor.** Use an empty `cursorDelegate`. Blinking elements can be in their off phase in any one screenshot

## Sizing and layout

- **`Loader` with `anchors.fill: parent` on an unsized `Item` makes the item 0×0.** It still draws but can't be clicked. Bind real `width`/`height` to the implicit size on the wrapper
- **`Layout.preferredWidth` is only a hint.** A fixed-width child next to a `fillWidth` sibling needs `minimumWidth` and `maximumWidth` too. Then let something else shrink and elide
- **A `Chamfer` inside a `Layout` needs a sized wrapper `Item`**

## Bindings that don't re-run

- **`Grid` implicit size goes stale** with the `rows: 1000`/`columns: 1000` trick. Don't bind to it
- **Sums over `repeater.itemAt(i)` don't register dependencies.** Add an `int` counter, bump it in each item's `onWidthChanged`/`onHeightChanged`, and read it at the top of the binding
- **Anchors built from a size that changed that way go stale too.** Use plain `x`/`y` bindings (`x: (parent.width - width) / 2`)
- **Conditional anchors don't re-resolve after `Settings` loads.** Same fix
- **`Quickshell.screens[0]` doesn't reliably invalidate bindings,** and `===` against it fails on real multi-monitor hardware. Compute "am I primary" into a stored property from `onScreenChanged` and `Component.onCompleted`

## Modules and names

- **A singleton named after a QtQuick type gets shadowed.** Qt 6.12's `QtQuick.Color` hid crux's `Color`, and the whole shell went unthemed. Check `/usr/lib/qt6/qml/QtQuick/plugins.qmltypes` before naming one
- **A dynamically loaded file can't import a module nothing static references.** Add a bare `import qs.Modules.<Dir>` to `shell.qml`
- **Writing an undeclared property throws, reading one gives `undefined`.** Check before forwarding optional properties to a loaded item

## Repeaters and delegates

- **A call that rebuilds a `Repeater` destroys the delegate running the handler.** Capture what you need before the call
- **A `Repeater` removes delegates instantly,** so there's no exit animation. Use a `ListView` with a `remove` transition

## IPC

- **Two instances registering the same target means one silently loses.** It may only show after `Configuration Loaded`. Declare screen-agnostic targets once, outside `Variants`
- **`qs ipc call <target> show` runs the CLI's own `show`.** Don't name a function `show`

## Services

- **`PowerProfiles.hasPerformanceProfile` is false for about the first second.** Bind to it. Don't read it once at startup
- **Scroll Lock always reads "unknown".** `hyprctl devices -j` doesn't report it and this box has no scroll-lock LED in sysfs. Not a crux bug

## Text-input warning on every popup close

`qt.qpa.wayland.textinput: ... Trying to disable <surface> but 0x0 is focused` fires each time a layer surface drops `WlrKeyboardFocus.Exclusive`. It isn't crux: a 20-line config that only toggles keyboard focus reproduces it. Hyprland sends the text-input leave before the keyboard leave, so Qt's disable finds nothing focused. Crux launches with `--log-rules qt.qpa.wayland.textinput.warning=false` (in `exec.lua` and [`dev-loop.md`](../agents/skills/dev-loop.md)). `//@ pragma Env QT_LOGGING_RULES=...` does not work; quickshell's own log filter overrides it.

## Assigning an undeclared property throws, but only when it runs

Reading `root.foo` when `foo` was never declared gives `undefined` with no warning, so bindings that read it look fine and the boot log stays clean. Assigning `root.foo = true` throws `Cannot assign to non-existent property "foo"` and aborts the rest of the function. When a refactor moves a property out of a file, grep for every remaining `root.<name>` in it. This silently broke Wallhaven downloads from 2026-09-10 to 2026-10-17: `_downloadAndApply` threw on `root.downloading = true`, one line before it would have started curl.

