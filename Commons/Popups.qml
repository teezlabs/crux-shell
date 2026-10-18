pragma Singleton

import QtQuick
import Quickshell

// In-process handle on every popup surface by name and screen, so callers skip qs ipc (docs/design-notes.md, "Popups call each other directly").
Singleton {
  id: root

  // "<name>@<screen>" -> surface. Not notifying; only read imperatively.
  property var surfaces: ({})

  function key(name, screen): string {
    const screenName = !screen ? "" : (screen.name !== undefined ? screen.name : screen);
    return name + "@" + screenName;
  }

  function register(name, screen, surface): void {
    root.surfaces[root.key(name, screen)] = surface;
  }

  function unregister(name, screen): void {
    delete root.surfaces[root.key(name, screen)];
  }

  // Closes every popup on every screen; the focus grabs call this on an outside click.
  function closeAll(): void {
    for (const k in root.surfaces) {
      const s = root.surfaces[k];
      if (s && s.close)
        s.close();
    }
  }

  // Falls back to a screen-less registration for callers that don't know their screen.
  function find(name, screen): var {
    return root.surfaces[root.key(name, screen)] || root.surfaces[root.key(name, null)] || null;
  }

  function openAt(name, screen, x, y): void {
    const s = root.find(name, screen);
    if (!s)
      return;
    if (s.openAt)
      s.openAt(x, y);
    else
      s.open();
  }

  // Tells a surface which bar module to fold into, so it rests collapsed at that size. No-op if it doesn't morph.
  function setMorphSource(name, screen, x, y, w, h): void {
    const s = root.find(name, screen);
    if (s && s.setMorphSource)
      s.setMorphSource(x, y, w, h);
  }

  // Grows the surface out of the bar module at (x, y, w, h); falls back to openAt.
  function openFrom(name, screen, x, y, w, h): void {
    const s = root.find(name, screen);
    if (!s)
      return;
    if (s.openFrom)
      s.openFrom(x, y, w, h);
    else if (s.openAt)
      s.openAt(x, y);
    else
      s.open();
  }

  function open(name, screen): void {
    const s = root.find(name, screen);
    if (s)
      s.open();
  }

  function close(name, screen): void {
    const s = root.find(name, screen);
    if (s)
      s.close();
  }

  // Settings is the only surface with a deeper entry point than open().
  function openTab(name, screen, tab): void {
    const s = root.find(name, screen);
    if (s && s.openTab)
      s.openTab(tab);
  }

  function toggle(name, screen): void {
    const s = root.find(name, screen);
    if (s)
      s.toggle();
  }
}
