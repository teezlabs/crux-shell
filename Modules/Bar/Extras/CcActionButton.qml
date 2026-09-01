import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons

// Control Center 3x2 action-grid button (§6.3): plain bordered cell,
// centred label-xs text, optional real icon-theme icon to its left (empty
// `icon` just shows the label alone — no placeholder glyph forced in).
// `enabled: false` (no backing tool installed, e.g. RECORD/COLOR without
// wf-recorder/hyprpicker) dims it and blocks taps rather than pretending
// the action works. `active` highlights a toggle-style action (IDLE OFF/ON)
// the same way a lit toggle tile would.
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
