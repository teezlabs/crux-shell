import QtQuick
import QtQuick.Effects
import qs.Commons

// The real Arch Linux distro mark (/usr/share/pixmaps/archlinux-logo.svg,
// shipped by the archlinux-logos package on every Arch box), recolored to
// the active matugen accent via MultiEffect's full colorization rather than
// Arch's own fixed brand blue — so it re-tints along with every other
// themed element when the palette changes instead of standing out as a
// fixed color.
Item {
  id: root

  property color tintColor: Color.primary

  Image {
    id: logo
    anchors.fill: parent
    source: "file:///usr/share/pixmaps/archlinux-logo.svg"
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
    sourceSize: Qt.size(root.width, root.height)
    visible: false
  }

  MultiEffect {
    anchors.fill: parent
    source: logo
    colorization: 1
    colorizationColor: root.tintColor
  }
}
