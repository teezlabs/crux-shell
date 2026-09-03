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
  property bool colorize: true

  implicitWidth: 16
  implicitHeight: 16

  IconImage {
    id: img
    anchors.fill: parent
    source: root.fallbackIconName !== "" ? Quickshell.iconPath(root.iconName, root.fallbackIconName) : Quickshell.iconPath(root.iconName)
    visible: source !== ""

    layer.enabled: root.colorize
    layer.effect: ShaderEffect {
      property color targetColor: root.color
      property real colorizeMode: 1.0
      fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Assets/Shaders/appicon_colorize.frag.qsb")
    }
  }
}
