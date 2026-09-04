import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons

// An icon-theme glyph recoloured to `color`, so symbolic icons follow
// light/dark. `colorize: false` for real app icons. See the crux skill's
// notes.md.
Item {
  id: root

  property string iconName: ""
  property string fallbackIconName: ""
  property color color: Color.surfaceText
  // Off for real app icons — the tray and the launcher show full-colour
  // logos, which are legible in either mode and would be flattened to a
  // single tone by the shader.
  property bool colorize: true
  // For callers that already hold a URL or path rather than a theme name.
  property string source: ""
  property alias asynchronous: img.asynchronous

  implicitWidth: 16
  implicitHeight: 16

  IconImage {
    id: img
    // Explicit size, not anchors.fill: an IconImage rasterises SVGs at the
    // size it believes it is, and filling meant it asked for a buffer
    // before geometry settled — 159 "requested buffer size is too big"
    // warnings from the launcher's app list alone.
    width: root.width
    height: root.height
    x: 0
    y: 0
    source: {
      if (root.source !== "")
        return root.source;
      if (root.iconName === "")
        return "";
      return root.fallbackIconName !== "" ? Quickshell.iconPath(root.iconName, root.fallbackIconName) : Quickshell.iconPath(root.iconName);
    }
    visible: source !== ""

    layer.enabled: root.colorize
    layer.effect: ShaderEffect {
      property color targetColor: root.color
      property real colorizeMode: 1.0
      fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Assets/Shaders/appicon_colorize.frag.qsb")
    }
  }
}
