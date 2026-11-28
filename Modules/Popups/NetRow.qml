import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// A network or device line: icon box (or a signal/battery ring), title, subtitle, trailing status, and a ⋮ that
// reveals the row's actions underneath it. `actions` is [{ label, symbol, tone }]; tone "error" tints it red.
ColumnLayout {
  id: root

  property string symbol: ""
  // 0-100 draws a ring around the icon (signal, battery); -1 draws the icon box.
  property int ring: -1
  property string title: ""
  property string subtitle: ""
  // Right-aligned text before the lock and ⋮ (a percentage, "Connecting…").
  property string trailing: ""
  property color trailingColor: Colors.labelText
  property bool locked: false
  // The active connection: lit icon and a brighter title.
  property bool highlighted: false
  property bool interactive: true
  property var actions: []
  property bool _menuOpen: false

  signal tapped
  signal actionTriggered(int index)

  Layout.fillWidth: true
  spacing: Tokens.spaceXs

  Item {
    Layout.fillWidth: true
    implicitHeight: 46

    PopupRowBackground {
      anchors.fill: parent
      hovered: root.interactive && rowHover.hovered
    }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Tokens.spaceSm
      anchors.rightMargin: Tokens.spaceXs
      spacing: Tokens.spaceMd

      Item {
        Layout.preferredWidth: 34
        Layout.preferredHeight: 34

        Chamfer {
          visible: root.ring < 0
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: root.highlighted ? Colors.primary : Colors.surfaceContainerHigh
        }

        // Ring: a faint full track with the value drawn over it from the top.
        Canvas {
          id: ringCanvas
          visible: root.ring >= 0
          anchors.fill: parent
          readonly property real value: Math.max(0, Math.min(100, root.ring)) / 100
          readonly property color track: Colors.surfaceContainerHigh
          readonly property color fill: root.highlighted ? Colors.primary : Colors.surfaceTextMuted
          onValueChanged: requestPaint()
          onTrackChanged: requestPaint()
          onFillChanged: requestPaint()
          onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const r = width / 2 - 2;
            ctx.lineWidth = 2.5;
            ctx.strokeStyle = track;
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, r, 0, Math.PI * 2);
            ctx.stroke();
            ctx.strokeStyle = fill;
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * value);
            ctx.stroke();
          }
        }

        NSymbol {
          anchors.centerIn: parent
          name: root.symbol
          size: root.ring >= 0 ? 16 : 19
          filled: root.highlighted
          color: root.ring < 0 && root.highlighted ? Colors.primaryText : (root.highlighted ? Colors.primary : Colors.surfaceText)
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        NText {
          Layout.fillWidth: true
          text: root.title
          size: NText.Size.BodySm
          font.weight: root.highlighted ? Font.DemiBold : Font.Normal
          color: Colors.surfaceText
        }
        NText {
          Layout.fillWidth: true
          visible: text !== ""
          text: root.subtitle
          size: NText.Size.Caption
          color: root.highlighted ? Colors.primary : Colors.labelText
        }
      }

      NText {
        visible: text !== ""
        text: root.trailing
        size: NText.Size.Caption
        color: root.trailingColor
      }

      NSymbol {
        visible: root.locked
        name: "lock"
        size: 14
        color: Colors.labelText
      }

      Item {
        visible: root.actions.length > 0
        Layout.preferredWidth: 26
        Layout.preferredHeight: 30

        NSymbol {
          anchors.centerIn: parent
          name: "more_vert"
          size: 18
          color: menuHover.hovered || root._menuOpen ? Colors.primary : Colors.surfaceTextMuted
        }
        HoverHandler {
          id: menuHover
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: root._menuOpen = !root._menuOpen
        }
      }
    }

    HoverHandler {
      id: rowHover
      enabled: root.interactive
      cursorShape: Qt.PointingHandCursor
    }
    TapHandler {
      enabled: root.interactive
      onTapped: eventPoint => {
        // The ⋮ handles its own taps.
        if (root.actions.length > 0 && eventPoint.position.x > parent.width - 32)
          return;
        root.tapped();
      }
    }
  }

  // The ⋮ actions, under the row.
  RowLayout {
    visible: root._menuOpen && root.actions.length > 0
    Layout.fillWidth: true
    Layout.leftMargin: 34 + Tokens.spaceMd + Tokens.spaceSm
    Layout.bottomMargin: Tokens.spaceXs
    spacing: Tokens.spaceXs

    Repeater {
      model: root.actions

      delegate: Item {
        id: act
        required property var modelData
        required property int index
        readonly property bool danger: act.modelData.tone === "error"
        implicitWidth: actRow.implicitWidth + Tokens.spaceLg * 2
        implicitHeight: 26

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: actHover.hovered ? Colors.alpha(act.danger ? Colors.error : Colors.primary, 0.16) : Colors.surfaceContainerLow
          strokeColor: act.danger ? Colors.alpha(Colors.error, actHover.hovered ? 0.7 : Tokens.destructiveBorderAlpha * 2) : (actHover.hovered ? Colors.alpha(Colors.primary, 0.6) : Colors.outlineVariant)
          strokeWidth: Tokens.borderModule
        }
        RowLayout {
          id: actRow
          anchors.centerIn: parent
          spacing: Tokens.spaceXs
          NSymbol {
            visible: !!act.modelData.symbol
            name: act.modelData.symbol || ""
            size: 14
            color: act.danger ? Colors.error : Colors.surfaceText
          }
          NText {
            text: act.modelData.label.toUpperCase()
            tracking: true
            size: NText.Size.LabelXs
            font.weight: Font.DemiBold
            color: act.danger ? Colors.error : Colors.surfaceText
          }
        }
        HoverHandler {
          id: actHover
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: {
            root._menuOpen = false;
            root.actionTriggered(act.index);
          }
        }
      }
    }

    Item {
      Layout.fillWidth: true
    }
  }
}
