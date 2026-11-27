import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.Commons

// Flickable with a thin scrollbar shown on overflow. The bar sets its own implicitWidth (docs/qml-gotchas.md).
Flickable {
  id: root

  property real handleWidth: 4
  // Room kept clear on the right so the bar never sits on the content.
  readonly property real gutter: root.handleWidth + Tokens.spaceMd

  clip: true
  boundsBehavior: Flickable.StopAtBounds
  contentWidth: width - root.gutter
  flickDeceleration: 3000

  readonly property bool scrollable: contentHeight > height

  // A page shown again starts at the top, not wherever it was last left.
  onVisibleChanged: if (visible) {
    wheel.stop();
    root.contentY = 0;
  }

  NSmoothWheel {
    id: wheel
    flickable: root
  }

  NScrollFade {
    id: fade
    flickable: root
  }

  layer.enabled: fade.active
  layer.effect: MultiEffect {
    maskEnabled: true
    maskSource: fade
    maskThresholdMin: 0.5
    maskSpreadAtMin: 1
  }

  ScrollBar.vertical: ScrollBar {
    id: bar
    policy: root.scrollable ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
    implicitWidth: root.handleWidth
    padding: 0

    contentItem: Rectangle {
      implicitWidth: root.handleWidth
      implicitHeight: 40
      color: bar.pressed ? Colors.primary : Colors.alpha(Colors.surfaceTextMuted, bar.hovered ? 0.6 : 0.35)
    }
  }
}
