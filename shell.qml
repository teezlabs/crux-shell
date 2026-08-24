// crux shell — boot smoke test. Launch with `qs -c crux`.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Modules.Bar
import qs.Modules.OSD
import qs.Modules.Polkit
// Not instantiated here — SettingsWindow is opened by the dynamically
// Loader-loaded Settings.qml bar widget, which can't resolve a qs.Modules.*
// module on its own. Statically importing it once here registers it with
// the engine so the dynamic loader's own `import qs.Modules.SettingsPanel`
// resolves. See crux skill for the full gotcha writeup.
import qs.Modules.SettingsPanel

ShellRoot {
  PolkitAgent {}

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: root
      required property var modelData
      screen: modelData

      readonly property string barPosition: Settings.isLoaded ? Settings.getBarPositionForScreen(screen.name) : "top"
      readonly property bool barIsVertical: barPosition === "left" || barPosition === "right"

      anchors {
        top: barPosition === "top" || barIsVertical
        bottom: barPosition === "bottom" || barIsVertical
        left: barPosition === "left" || !barIsVertical
        right: barPosition === "right" || !barIsVertical
      }
      // When vertical, top+bottom anchors fill height and only implicitWidth matters (and vice versa).
      implicitWidth: 32
      implicitHeight: 32
      color: "#1e1e2e"

      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.namespace: "crux-bar"
      WlrLayershell.exclusionMode: ExclusionMode.Auto

      Bar {
        screen: root.screen
      }

      VolumeOsd {
        targetScreen: root.screen
      }
    }
  }
}
