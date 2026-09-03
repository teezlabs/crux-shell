import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons

// A themed icon: an icon-theme glyph recolored to `color`.
//
// Symbolic icon themes ship one fixed colour, usually light because they
// assume a dark shell. That works until the shell goes light, at which
// point white glyphs sit on a white surface and vanish. The shader takes
// the glyph's intensity and paints it in whatever colour the theme calls
// for, so an icon follows light/dark like everything else.
//
// Ported from noctalia's appicon_colorize.frag. colorizeMode 1.0 is its
// "tray" path: max-channel intensity with a smoothstep, which normalises
// symbolic glyphs of differing weights.
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
