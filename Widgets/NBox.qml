import QtQuick
import qs.Commons

// Chamfered, fill-only group container for a set of fields or buttons.
Item {
  id: root

  property color fillColor: Colors.surfaceContainer
  property color strokeColor: "transparent"
  property int chamferSize: Tokens.chamferModule
  property bool invertChamfer: false
  property real padding: 14
  default property alias content: contentItem.data

  implicitWidth: contentItem.implicitWidth + root.padding * 2
  implicitHeight: contentItem.implicitHeight + root.padding * 2

  Chamfer {
    anchors.fill: parent
    chamferSize: root.chamferSize
    cutTopLeft: root.invertChamfer
    cutBottomRight: root.invertChamfer
    cutTopRight: !root.invertChamfer
    cutBottomLeft: !root.invertChamfer
    fillColor: root.fillColor
    strokeColor: root.strokeColor
    strokeWidth: root.strokeColor.a > 0 ? Tokens.borderModule : 0
  }

  Item {
    id: contentItem
    anchors.fill: parent
    anchors.margins: root.padding
  }
}
