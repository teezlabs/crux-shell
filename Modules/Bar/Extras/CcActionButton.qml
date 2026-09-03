import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Widgets

// Control Center action-grid button. `enabled: false` dims and blocks taps when a backing tool is missing; `active` highlights toggle-style actions.
Item {
  id: root

  property string label: ""
  property string icon: ""
  // Non-symbolic twin, tried when the theme lacks the symbolic one.
  property string iconFallback: ""
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

    NIcon {
      visible: root.icon !== ""
      anchors.verticalCenter: parent.verticalCenter
      width: 12
      height: 12
      iconName: root.icon
      fallbackIconName: root.iconFallback
      color: Color.surfaceText
    }

    NText {
      tracking: true
      anchors.verticalCenter: parent.verticalCenter
      text: root.label
      color: root.active ? Color.primary : Color.surfaceText
      size: NText.Size.LabelXs
      font.weight: Font.DemiBold
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
