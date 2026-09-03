import QtQuick
import qs.Commons

// Chamfered group container for a set of fields or buttons. The chamfer
// tier and the two-opposite-corner convention match every other surface.
Item {
  id: root

  property color fillColor: Color.surfaceContainer
  property color strokeColor: Color.outline
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
    strokeWidth: Tokens.borderModule
  }

  Item {
    id: contentItem
    anchors.fill: parent
    anchors.margins: root.padding
  }
}
