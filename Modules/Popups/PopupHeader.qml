import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Popup title row: optional back arrow, tracked label, optional meta, optional action, trailing controls.
RowLayout {
  id: root

  property string title: ""
  property string meta: ""
  property string action: ""
  property color actionColor: Colors.error
  signal actionTapped
  // A back arrow before the title, for a sub-page inside another panel.
  property bool showBack: false
  signal backTapped

  default property alias trailing: trail.data

  Layout.fillWidth: true
  spacing: Tokens.spaceMd

  Item {
    visible: root.showBack
    Layout.preferredWidth: 22
    Layout.preferredHeight: 22
    Layout.leftMargin: -Tokens.spaceXs

    NSymbol {
      anchors.centerIn: parent
      name: "chevron_right"
      rotation: 180
      size: 20
      color: backHover.hovered ? Colors.primary : Colors.surfaceText
    }
    HoverHandler {
      id: backHover
      cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
      onTapped: root.backTapped()
    }
  }

  NText {
    tracking: true
    text: root.title
    color: root.showBack ? Colors.surfaceText : Colors.labelText
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
