import QtQuick

// Keeps a popup surface registered in Popups under its current screen.
// Registering at Component.onCompleted alone is too early for a surface
// created inside a bar widget — see the crux skill's notes.md.
QtObject {
  id: root

  required property string name
  required property var surface
  required property var screen

  property string registeredScreen: ""
  // Distinguishes "never registered" from "registered under the empty
  // screen key", so the placeholder entry made before targetScreen
  // arrives gets cleaned up rather than left dangling.
  property bool registered: false

  function sync(): void {
    const next = root.screen && root.screen.name ? root.screen.name : "";
    if (root.registered && root.registeredScreen !== next)
      Popups.unregister(root.name, root.registeredScreen);
    Popups.register(root.name, root.screen, root.surface);
    root.registeredScreen = next;
    root.registered = true;
  }

  onScreenChanged: root.sync()
  Component.onCompleted: root.sync()
  Component.onDestruction: {
    if (root.registered)
      Popups.unregister(root.name, root.registeredScreen);
  }
}
