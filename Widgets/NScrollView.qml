import QtQuick
import QtQuick.Controls
import qs.Commons

// Flickable scroll container with a thin flat scrollbar, shown whenever the
// content actually overflows.
//
// The bar carries its own implicitWidth: a ScrollBar sizes itself from its
// background and contentItem, so overriding the background with an empty
// Item (to drop the stock track) collapses it to zero width and it renders
// nothing at all, silently.
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
    policy: root.scrollable ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
    implicitWidth: root.handleWidth
    padding: 0

    contentItem: Rectangle {
      implicitWidth: root.handleWidth
      implicitHeight: 40
      color: bar.pressed ? Color.primary : Color.alpha(Color.surfaceTextMuted, bar.hovered ? 0.6 : 0.35)
    }
  }
}
