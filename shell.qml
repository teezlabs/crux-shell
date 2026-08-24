// crux shell — boot smoke test. Launch with `qs -c crux`.

import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: root
      required property var modelData
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }
      implicitHeight: 32
      color: "#1e1e2e"

      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.namespace: "crux-bar"
      WlrLayershell.exclusionMode: ExclusionMode.Auto

      Text {
        anchors.centerIn: parent
        text: "crux shell — " + root.screen.name
        color: "#cdd6f4"
        font.pixelSize: 14
      }
    }
  }
}
