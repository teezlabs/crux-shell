// crux login screen for greetd: `qs -p <crux dir>/greeter.qml`, run by the greeter user inside its own compositor.
// Outside greetd it opens as a preview that never authenticates; Escape closes it.

import QtQuick
import Quickshell
import qs.Modules.Greeter

ShellRoot {
  GreeterContext {
    id: greeterContext
  }

  Variants {
    model: Quickshell.screens

    GreeterSurface {
      required property var modelData
      screen: modelData
      context: greeterContext
    }
  }
}
