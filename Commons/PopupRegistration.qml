import QtQuick

// Keeps a popup surface registered in Popups under its current screen, re-registering when the screen arrives.
QtObject {
  id: root

  required property string name
  required property var surface
  required property var screen

  property string registeredScreen: ""
  // Separates "never registered" from "registered under no screen", so the placeholder entry gets cleaned up.
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
