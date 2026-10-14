import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Title row shared by every bar-flush popup: tracked label, optional
// caption meta, optional text action, then any trailing controls.
RowLayout {
  id: root

  property string title: ""
  property string meta: ""
  property string action: ""
  property color actionColor: Colors.error
  signal actionTapped

  default property alias trailing: trail.data

  Layout.fillWidth: true
  spacing: Tokens.spaceMd

  NText {
    tracking: true
    text: root.title
    color: Colors.labelText
    size: NText.Size.LabelXs
    font.weight: Font.DemiBold
    Layout.fillWidth: true
  }

  NText {
    visible: root.meta !== ""
    text: root.meta
    color: Colors.labelText
    size: NText.Size.Caption
  }

  NText {
    tracking: true
    visible: root.action !== ""
    text: root.action
    color: root.actionColor
    opacity: actionHover.hovered ? 1 : 0.8
    size: NText.Size.LabelXs
    font.weight: Font.DemiBold

    HoverHandler {
      id: actionHover
      cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
      onTapped: root.actionTapped()
    }
  }

  Row {
    id: trail
    visible: children.length > 0
    spacing: Tokens.spaceMd
  }
}
