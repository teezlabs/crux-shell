import QtQuick
import qs.Commons
import qs.Widgets

// Chamfered toggle pill used across the wallpaper browser's filter and footer bars.
Item {
  id: root

  property string text: ""
  property bool selected: false
  signal tapped

  implicitWidth: label.implicitWidth + 18
  implicitHeight: 24

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferIcon
    cutTopRight: true
    cutBottomLeft: true
    fillColor: root.selected ? Colors.primaryContainer : (hover.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer)
    strokeColor: root.selected ? Colors.primary : Colors.outline
    strokeWidth: Tokens.borderModule
  }

  NText {
    id: label
    anchors.centerIn: parent
    tracking: true
    text: root.text
    color: root.selected ? Colors.primaryContainerText : Colors.surfaceText
    size: NText.Size.LabelXs
  }

  HoverHandler {
    id: hover
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    onTapped: root.tapped()
  }
}
