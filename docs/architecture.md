# Architecture

Crux is one QuickShell process (`qs -c crux`), rooted at `shell.qml`. Per-screen surfaces are built inside `Variants` over `Quickshell.screens`. Shell-wide objects (`PopupAliases`, `PolkitAgent`) sit outside it and exist once.

## Layout

```
shell.qml                # root: per-screen Variants, global singletons, static module imports
Commons/                 # tokens and the settings store; imports nothing from Modules/Widgets
  Colors, Tokens, ColorSchemes, FontService, FuzzySort
  Popups, PopupRegistration, Toast, TooltipService
  Settings.qml + SettingsSchema/<Domain>Settings.qml
Services/                # singletons that own a process, DBus connection or hardware state
Widgets/                 # the UI kit: N* controls, Chamfer, ConcaveCorner, NPanelWindow,
                         # NPressFeedback, and shared pieces like SegMeter and CircularGauge
Modules/
  Bar/
    Bar.qml              # left/center/right sections from Settings.getBarWidgetsForScreen()
    Extras/              # bar plumbing only: BarSection, BarModule, BarIconButton,
                         # BarPill, BarWidgetLoader, BarWidgetRegistry, TrayCell
    Widgets/<Id>.qml     # one file per bar widget; file name == registry id
  Popups/
    PopupHost.qml        # one always-mapped overlay per screen, hosts every bar-flush popup
    SlideCard, PopupIpc, PopupAlias(es), PopupHeader, PopupRowBackground
    Contents/            # popup bodies (<X>PopupContent.qml) and their *Model.js
  ControlCenter/         # Cc* components and toggles
  <Feature>/             # Launcher, Notifications, Sidebar, SessionMenu, Wallpaper,
                         # Background, LockScreen, OSD, Polkit, Tooltip, SettingsPanel
Assets/                  # bundled fonts and images
bin/crux-*               # CLI helpers, many ported from Omarchy
packaging/               # PKGBUILD (AUR source of truth), sudoers grants
docs/                    # this reference; the visual spec PDF
agents/skills/           # task guides for working on crux
```

## Layering

Imports point down this list, never up:

1. `Commons/`
2. `Services/`
3. `Widgets/`
4. `Modules/`
5. `shell.qml`

A `Commons` singleton importing `Modules` or `Widgets` is a bug.

## Where things go

- **Shows state on the bar:** `Modules/Bar/Widgets/`
- **Interaction behind a click:** a popup in `Modules/Popups/Contents/` or a `NPanelWindow`
- **Owns hardware, a process or DBus:** `Services/`
- **Reused by two or more modules:** `Widgets/`
- **A design value (color, size, duration):** `Commons/Tokens.qml` or `Commons/Colors.qml`
- **User plugins:** `~/.config/crux/plugins/<name>/` with `manifest.json` + `Widget.qml`, loaded by `Services/Plugins.qml`

## Still open

- Dragging the whole bar to another screen edge
- A smooth-scrolling setting
- Notification exit animation
- `Modules/Wallpaper/WallpaperBrowserWindow.qml` is ~1,150 lines. The rail, grid and detail panel are still inline
- Border logic is bugged (reported 2026-10-18): a border draws as a plain square instead of following the chamfer. Suspects are the `Rectangle { border.* }` outlines that sit on chamfered surfaces (`SettingsSidebar.qml`, `SidebarWindow.qml`, the armed tile in `PowerMenuWindow.qml`, `TrayCell.qml`); chamfer-following strokes must come from `Chamfer.qml`'s own stroke
