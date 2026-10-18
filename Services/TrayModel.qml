pragma Singleton

import QtQuick
import Quickshell
import qs.Commons

// Helpers shared by the Tray widget and its drawer.
Singleton {
  id: root

  // Pins are keyed by the DBus id, which survives restarts; titles drift and would silently unpin.
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

  // The chevron points the way the drawer's icons travel.
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
