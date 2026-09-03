import QtQuick
import QtQuick.Controls
import qs.Commons

// Flickable scroll container with a thin flat scrollbar, shown only while
// the content actually overflows.
Flickable {
  id: root

  property real handleWidth: 4

  clip: true
  boundsBehavior: Flickable.StopAtBounds
  contentWidth: width
  flickDeceleration: 3000

  readonly property bool scrollable: contentHeight > height

  ScrollBar.vertical: ScrollBar {
    id: bar
    policy: root.scrollable ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
    width: root.handleWidth

    contentItem: Rectangle {
      implicitWidth: root.handleWidth
      color: bar.pressed ? Color.primary : Color.alpha(Color.surfaceTextMuted, bar.hovered ? 0.6 : 0.35)
    }

    background: Item {}
  }
}
