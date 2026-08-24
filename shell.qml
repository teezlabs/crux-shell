// crux shell — boot smoke test. Launch with `qs -c crux`.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

ShellRoot {
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

      Text {
        anchors.centerIn: parent
        text: "crux shell — " + root.screen.name + " (" + root.barPosition + ")"
        color: "#cdd6f4"
        font.pixelSize: 14
        rotation: root.barIsVertical ? 90 : 0
      }
    }
  }
}
