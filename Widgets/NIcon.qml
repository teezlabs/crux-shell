import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons

// Icon-theme glyph recoloured to `color` (docs/design-notes.md, "Icons").
Item {
  id: root

  property string iconName: ""
  property string fallbackIconName: ""
  property color color: Colors.surfaceText
  // Eases colour like NText and Chamfer, which matters on a retheme.
  property bool animateColor: true
  // Off for real app icons (tray, launcher), which the shader would flatten.
  property bool colorize: true
  // For callers that already hold a URL or path rather than a theme name.
  property string source: ""
  property alias asynchronous: img.asynchronous

  implicitWidth: 16
  implicitHeight: 16

  // The shader reads _animatedColor so the tween runs on a plain property.
  property color _animatedColor: root.color
  Behavior on _animatedColor {
    enabled: root.animateColor
    ColorAnimation {
      duration: Tokens.durationColor
      easing.type: Tokens.easingColor
    }
  }

  IconImage {
    id: img
    // Explicit size, not anchors.fill, or IconImage requests buffers before geometry settles (docs/design-notes.md).
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
      property color targetColor: root._animatedColor
      property real colorizeMode: 1.0
      fragmentShader: Qt.resolvedUrl(Quickshell.shellDir + "/Assets/Shaders/appicon_colorize.frag.qsb")
    }
  }
}
