import QtQuick
import QtQuick.Controls
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
  onVisibleChanged: if (visible)
    root.contentY = 0

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
