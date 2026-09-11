import QtQuick
import QtQuick.Effects
import qs.Commons

// Real Arch logo SVG, recolored to the active matugen accent via MultiEffect.
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
