import QtQuick
import qs.Commons
import qs.Widgets

// Hover/selection backdrop for a popup list row. Selected = the row's live
// item (connected network, default sink): a tint plus a left-edge marker.
Item {
  id: root

  property bool hovered: false
  property bool selected: false

  anchors.fill: parent

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferIcon
    cutTopRight: true
    cutBottomLeft: true
    fillColor: root.selected ? Colors.alpha(Colors.primary, root.hovered ? 0.16 : 0.10) : (root.hovered ? Colors.surfaceContainerHigh : "transparent")
  }

  Rectangle {
    visible: root.selected
    width: Tokens.borderMarker
    height: parent.height - Tokens.spaceMd * 2
    anchors.verticalCenter: parent.verticalCenter
    color: Colors.primary
  }
}
