import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons

// Control Center action-grid button. `enabled: false` dims and blocks taps when a backing tool is missing; `active` highlights toggle-style actions.
Item {
  id: root

  property string label: ""
  property string icon: ""
  property bool available: true
  property bool active: false
  signal tapped

  implicitHeight: 30

  Rectangle {
    anchors.fill: parent
    color: root.active ? Color.alpha(Color.primary, 0.14) : (hoverHandler.hovered && root.available ? Color.surfaceContainerHigh : Color.surfaceContainer)
    opacity: root.available ? 1 : 0.4
  }

  Row {
    anchors.centerIn: parent
    spacing: 6

    IconImage {
      visible: root.icon !== ""
      anchors.verticalCenter: parent.verticalCenter
      width: 12
      height: 12
      source: root.icon !== "" ? Quickshell.iconPath(root.icon, "") : ""
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: root.label
      color: root.active ? Color.primary : Color.surfaceText
      font.family: Tokens.fontFamily
      font.pixelSize: Tokens.labelXsSize
      font.weight: Font.DemiBold
      font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
    }
  }

  HoverHandler {
    id: hoverHandler
    enabled: root.available
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    enabled: root.available
    onTapped: root.tapped()
  }
}
