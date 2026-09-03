import QtQuick
import qs.Commons

// Square chamfered button whose content is a glyph drawn by the caller
// (Canvas today, an icon font once one is bundled). Same pointer-handler
// rule as NButton: no MouseArea.
Item {
  id: root

  property bool active: false
  property bool invertChamfer: false
  property real size: 26
  default property alias content: contentItem.data

  signal clicked
  signal rightClicked

  implicitWidth: root.size
  implicitHeight: root.size
  width: implicitWidth
  height: implicitHeight
  opacity: enabled ? 1.0 : 0.5

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferIcon
    cutTopLeft: root.invertChamfer
    cutBottomRight: root.invertChamfer
    cutTopRight: !root.invertChamfer
    cutBottomLeft: !root.invertChamfer
    fillColor: root.active ? Color.primaryContainer : (hover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer)
    strokeColor: root.active ? Color.primary : Color.outline
    strokeWidth: Tokens.borderModule
  }

  Item {
    id: contentItem
    anchors.fill: parent
  }

  HoverHandler {
    id: hover
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    enabled: root.enabled
    acceptedButtons: Qt.LeftButton
    onTapped: root.clicked()
  }
  TapHandler {
    enabled: root.enabled
    acceptedButtons: Qt.RightButton
    onTapped: root.rightClicked()
  }
}
