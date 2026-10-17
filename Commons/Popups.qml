pragma Singleton

import QtQuick
import Quickshell

// In-process handle on every named popup surface, keyed by name + screen —
// bar widgets call popups directly instead of forking `qs ipc` back into
// this same process. A surface exposes open()/close()/toggle(), optionally
// openAt(x, y). See the crux skill's notes.md.
Singleton {
  id: root

  // "<name>@<screenName>" -> surface object. Not a notifying property —
  // every read here is an imperative lookup, nothing binds to it.
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

  // Closes every registered popup on every screen. The focus grabs call this when a click
  // lands outside them, on any monitor.
  function closeAll(): void {
    for (const k in root.surfaces) {
      const s = root.surfaces[k];
      if (s && s.close)
        s.close();
    }
  }

  // Falls back to a screen-less registration so a caller that doesn't know
  // its screen still reaches a globally-unique surface.
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

  // Tells a surface which bar module it should fold into, so it can rest
  // collapsed at that size before it is ever opened. No-op for surfaces
  // that don't morph.
  function setMorphSource(name, screen, x, y, w, h): void {
    const s = root.find(name, screen);
    if (s && s.setMorphSource)
      s.setMorphSource(x, y, w, h);
  }

  // Morph-open: grows the surface out of the bar module at (x, y) sized
  // w x h. Falls back to openAt for surfaces that don't implement it.
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
