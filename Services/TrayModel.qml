pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Pure helpers shared by the Tray bar widget and its drawer: both need the
// same pinned/unpinned split off the same live SystemTray list, and neither
// owns the other. See the crux skill's notes.md.
Singleton {
  id: root

  // The identity a pin is stored against. `id` is the item's own DBus
  // service identifier and is what survives a restart; the human-readable
  // fields drift (a title can carry a message count) and would silently
  // unpin the item.
  function key(item): string {
    if (!item)
      return "";
    return item.id || item.tooltipTitle || item.title || "";
  }

  function label(item): string {
    if (!item)
      return "";
    return item.tooltipTitle || item.title || item.id || "";
  }

  // The drawer reveals itself alongside the chevron — leftward on a
  // horizontal bar, upward on a vertical one — so the arrow points the way
  // the icons travel.
  function expandIcon(vertical): string {
    return vertical ? "arrow-up-symbolic" : "arrow-left-symbolic";
  }

  function collapseIcon(vertical): string {
    return vertical ? "arrow-down-symbolic" : "arrow-right-symbolic";
  }

  // Adds or removes one item from a Tray widget's own pinned list.
  function togglePin(screenName, section, index, item): void {
    if (section === "" || index < 0)
      return;
    const widgets = Settings.getBarWidgetsForScreen(screenName)[section];
    if (!widgets || index >= widgets.length)
      return;
    const entry = widgets[index];
    if (!entry || entry.id !== "Tray")
      return;

    const id = root.key(item);
    if (id === "")
      return;
    const list = (entry.pinned || []).slice();
    const at = list.indexOf(id);
    if (at === -1)
      list.push(id);
    else
      list.splice(at, 1);

    Settings.updateBarWidget(screenName, section, index, {
      "pinned": list
    });
  }
}
