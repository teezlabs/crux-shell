# Settings

Read this before adding a setting or touching the settings panel.

## Storage

- `Commons/Settings.qml` is crux's own lean JSON store, backed by `~/.config/crux/settings.json`. It's not a copy of noctalia's
- The schema is split by domain: `Commons/SettingsSchema/<Domain>Settings.qml`. Add a setting to the matching domain file, or create a new one
- `Commons/` must never import `Modules/` or `Widgets/`. Settings once collected six such imports by accident
- **Write sub-properties, not whole objects.** `data.bar.widgets = widgets` silently doesn't persist. Assign `data.bar.widgets[section] = list` instead

## Panel tabs

- `Modules/SettingsPanel/SettingsWindow.qml` holds the `tabs` array (`{id, label, section, icon, description}`). It's the authoritative list, in sidebar order. The sidebar draws a section header wherever `section` changes: Personalize, Shell, System, Session, Advanced. Home has an empty `section`, so it sits above the first header; the panel opens on it
- Some ids outlived their labels: `general` is the Input tab and `idle` is the Power tab. `openTab` callers and `SettingsSearchIndex.qml` use the id
- Prefer a subtab on an existing tab over a new top-level tab for anything with only a setting or two (OSD lives under Notifications, the session menu under Power)
- A new tab is one entry there plus `<Name>Tab.qml`, shown with `visible: root.activeTab === "<id>"`. `icon` is a symbolic icon name that resolves through pixora-dark → breeze-dark (not Adwaita), shown in the sidebar and the page header; `description` is the one line under the page title
- A tab with several pages uses `Widgets/NTabBar.qml` and its own `subTab` property. A one-page tab skips the bar
- Every tab is built eagerly, so a clean boot log covers every tab's bindings, not just the one on screen
- Add a tab once a feature has a real setting rather than a hardcoded constant

## Row layout

Use `Controls/SettingRow.qml`. The title (and description) sit on the left, the controls on the right, and every row after the first in a section gets a divider above it.

- Give a description with `description: "..."`, or as a trailing `NText` with `size: NText.Size.Caption`, which the row moves under the title. A trailing `BodySm` `NText` is a readout and stays beside its control
- A control with `Layout.fillWidth: true` (a text field) makes the control side share the row with the title. Layouts default `fillWidth` to true, so a `RowLayout` control such as `NValueSlider` doesn't count
- Fixed-width `Layout` children next to a `fillWidth` sibling need `Layout.minimumWidth` and `Layout.maximumWidth` as well; `preferredWidth` alone gets ignored

Every subtab is a `Flickable`. A new slider's drag `MouseArea` needs `preventStealing: true`, as in `Widgets/NSlider.qml`, or the tab scrolls instead of the slider moving.
