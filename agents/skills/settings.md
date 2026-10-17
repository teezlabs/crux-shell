# Settings

Read this before adding a setting or touching the settings panel.

## Storage

- `Commons/Settings.qml` is crux's own lean JSON store, backed by `~/.config/crux/settings.json`. It's not a copy of noctalia's
- The schema is split by domain: `Commons/SettingsSchema/<Domain>Settings.qml`. Add a setting to the matching domain file, or create a new one
- `Commons/` must never import `Modules/` or `Widgets/`. Settings once collected six such imports by accident
- **Write sub-properties, not whole objects.** `data.bar.widgets = widgets` silently doesn't persist. Assign `data.bar.widgets[section] = list` instead

## Panel tabs

- `Modules/SettingsPanel/SettingsWindow.qml` holds the `tabs` array (`{id, label, section}`). It's the authoritative list, in sidebar order. The sidebar draws a section header wherever `section` changes: Personalize, Shell, System, Session, Advanced
- Some ids outlived their labels: `general` is the Input tab and `idle` is the Power tab. `openTab` callers and `SettingsSearchIndex.qml` use the id
- Prefer a subtab on an existing tab over a new top-level tab for anything with only a setting or two (OSD lives under Notifications, the session menu under Power)
- A new tab is one entry there plus `<Name>Tab.qml`, shown with `visible: root.activeTab === "<id>"`
- A tab with several pages uses `Widgets/NTabBar.qml` and its own `subTab` property. A one-page tab skips the bar
- Every tab is built eagerly, so a clean boot log covers every tab's bindings, not just the one on screen
- Add a tab once a feature has a real setting rather than a hardcoded constant

## Row layout

Use `Controls/SettingRow.qml`. It pins its label column with `Layout.minimumWidth` and `Layout.maximumWidth`, and lets the last child fill and elide. Any fixed-width `Layout` child next to a `fillWidth` sibling needs that same pinning. `preferredWidth` alone gets ignored.

Every subtab is a `Flickable`. A new slider's drag `MouseArea` needs `preventStealing: true`, as in `Widgets/NSlider.qml`, or the tab scrolls instead of the slider moving.
