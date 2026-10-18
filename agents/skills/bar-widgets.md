# Bar Widgets

Read this before adding or changing anything under `Modules/Bar/`.

## Adding a widget

1. Add the id to `Modules/Bar/Extras/BarWidgetRegistry.qml`
2. Create `Modules/Bar/Widgets/<Id>.qml`. File name, registry id and `widgetId` are the same string
3. Seed it into `~/.config/crux/settings.json` under `bar.widgets.<section>`
4. Boot-test ([`dev-loop.md`](dev-loop.md)) and verify it visually ([`visual-verification.md`](visual-verification.md))

Read `Modules/Bar/Widgets/` for the current widget list rather than trusting a count in a doc.

## Rules

- **Keep the widget small.** The bar icon shows state; real interaction (device lists, connect buttons) lives in a popup opened on click. See [`popups.md`](popups.md)
- **No `MouseArea`.** Use `TapHandler { onTapped: ... }` and `HoverHandler { cursorShape: ... }` (`hoverHandler.hovered` for hover state). A `MouseArea` anywhere in a widget stops `BarSection`'s long-press `TapHandler` from seeing any events, and drag-reordering silently dies for that widget
- **Size the wrapper.** Bind real `width: implicitWidth; height: implicitHeight`. Don't `anchors.fill` a `Loader` inside an unsized `Item`, or the widget renders but can't be clicked
- **No hardware ownership.** A process, DBus connection or polled value belongs in a `Services/` singleton. Widgets are built once per monitor, so a widget-owned poll runs once per screen. If the service only needs to poll while a widget exists, give it a `watchers` count and have the widget register itself with `Component.onCompleted: X.watchers++` and `Component.onDestruction: X.watchers--` (see `Services/Keyboard.qml`, `UpdatesService.qml`, `SystemStats.qml`). Prefer an event source over the poll when one exists (`nmcli monitor`, Hyprland raw events, UPower, `FileView` watches)
- **Glyphs:** don't trust emoji or system Nerd Font names on this box. Draw shapes, or load a bundled font from `Assets/Fonts/` with `FontLoader`. Edits near raw PUA glyphs can fail exact-string matching, so check bytes with `python3 -c "print(open(p,'rb').read())"`
- **New module imports:** a widget is loaded dynamically, so it can't resolve `import qs.Modules.<NewDir>` unless `shell.qml` statically imports that module too. Add a bare import there

## Vertical bars

The bar can sit on any edge (`Settings.data.bar.position`), and that can change at runtime.

- A widget with its own multi-item layout uses a `Grid` with `flow`/`rows`/`columns` swapped on `vertical`, not a fixed `Row` (see `Workspaces.qml`)
- A widget with text that won't fit a ~32px bar declares a `vertical` property and stacks or wraps its content (see `Clock.qml`, `Media.qml`). `BarWidgetLoader` forwards `vertical` only to widgets that declare it
- Position sections with plain `x`/`y` bindings, not anchors. Anchors and `Grid` implicit sizes go stale here. See [`docs/qml-gotchas.md`](../../docs/qml-gotchas.md)

## Drag reordering

`Modules/Bar/Extras/BarSection.qml` handles long-press-then-drag. A passive `TapHandler` detects the long press, then arms a `DragHandler` on the same press. All sections share the `"crux-bar-widget"` drag key, so cross-section drops work, and `Settings.moveBarWidget` commits them. If you touch it:

- `DragHandler` doesn't call `Drag.drop()` on release. It's called explicitly in `onActiveChanged`
- `Drag.drop()` rebuilds the `Repeater` and destroys the running delegate. Capture `dragState` and anything else before calling it
- The no-op guard skips only `fromIndex === toIndex`. Dropping on the next slot is a real move

Still open: dragging the whole bar to another screen edge.
