import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Control Center toggle tile: icon badge, name and live state. A chevron, when `expandable`, opens a detail list.
Item {
  id: root

  property string symbol: ""
  property string label: ""
  property string status: ""
  property bool active: false
  property bool available: true
  property bool expandable: false
  property bool expanded: false
  signal tapped
  signal chevronTapped

  implicitHeight: 52
  Layout.fillWidth: true
  opacity: root.available ? 1 : 0.45

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferModule
    cutTopRight: true
    cutBottomLeft: true
    fillColor: root.active ? Colors.alpha(Colors.primary, hover.hovered ? 0.2 : 0.14) : (hover.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainerLow)
    strokeColor: root.active ? Colors.alpha(Colors.primary, 0.55) : Colors.outlineVariant
    strokeWidth: Tokens.borderModule
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: Tokens.spaceMd
    anchors.rightMargin: root.expandable ? 0 : Tokens.spaceMd
    spacing: Tokens.spaceMd

    Item {
      id: badge
      Layout.preferredWidth: 34
      Layout.preferredHeight: 34

      Chamfer {
        anchors.fill: parent
        chamferSize: Tokens.chamferIcon
        cutTopRight: true
        cutBottomLeft: true
        fillColor: root.active ? Colors.primary : Colors.surfaceContainerHigh
      }

      NSymbol {
        anchors.centerIn: parent
        name: root.symbol
        size: 20
        filled: root.active
        color: root.active ? Colors.primaryText : Colors.surfaceText
      }

      NPressFeedback {
        id: press
        scaleTarget: badge
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 0

      NText {
        Layout.fillWidth: true
        text: root.label
        size: NText.Size.BodySm
        font.weight: Font.DemiBold
        color: Colors.surfaceText
      }
      NText {
        Layout.fillWidth: true
        visible: text !== ""
        text: root.status
        size: NText.Size.Caption
        color: root.active ? Colors.primary : Colors.labelText
      }
    }

    // The chevron is its own hit area, so the rest of the tile stays the on/off switch.
    Item {
      visible: root.expandable
      Layout.preferredWidth: 30
      Layout.fillHeight: true

      Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Tokens.borderDivider
        height: parent.height - Tokens.spaceLg * 2
        color: root.active ? Colors.alpha(Colors.primary, 0.35) : Colors.outlineVariant
      }

      NSymbol {
        anchors.centerIn: parent
        name: "chevron_right"
        size: 18
        rotation: root.expanded ? 90 : 0
        color: chevHover.hovered ? Colors.primary : Colors.surfaceTextMuted

        Behavior on rotation {
          NumberAnimation {
            duration: Tokens.durationPanel
            easing.type: Tokens.easingPanel
          }
        }
      }

      HoverHandler {
        id: chevHover
        enabled: root.available
        cursorShape: Qt.PointingHandCursor
      }
      TapHandler {
        enabled: root.available
        onTapped: root.chevronTapped()
      }
    }
  }

  HoverHandler {
    id: hover
    enabled: root.available
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    enabled: root.available
    onTapped: eventPoint => {
      // Taps on the chevron are handled there.
      if (root.expandable && eventPoint.position.x > root.width - 30)
        return;
      press.trigger();
      root.tapped();
    }
  }
}
