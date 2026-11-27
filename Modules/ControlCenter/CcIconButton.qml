import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

// Square chamfered icon button for Control Center shortcuts; `tone` tints it for active or destructive actions.
Item {
  id: root

  property string symbol: ""
  property string tooltip: ""
  // "" | "active" | "error"
  property string tone: ""
  property bool available: true
  property real size: 36
  signal tapped

  implicitWidth: root.size
  implicitHeight: root.size
  opacity: root.available ? 1 : 0.4

  readonly property color _accent: root.tone === "error" ? Colors.error : Colors.primary

  Chamfer {
    id: plate
    anchors.fill: parent
    chamferSize: Tokens.chamferIcon
    cutTopRight: true
    cutBottomLeft: true
    fillColor: root.tone === "active" ? Colors.primary : (hover.hovered ? Colors.alpha(root._accent, 0.16) : Colors.surfaceContainerLow)
    strokeColor: root.tone === "active" ? Colors.primary : (root.tone === "error" ? Colors.alpha(Colors.error, hover.hovered ? 0.7 : Tokens.destructiveBorderAlpha) : (hover.hovered ? Colors.alpha(Colors.primary, 0.5) : Colors.outlineVariant))
    strokeWidth: Tokens.borderModule
  }

  NSymbol {
    anchors.centerIn: parent
    name: root.symbol
    size: Math.round(root.size * 0.5)
    filled: root.tone === "active" || hover.hovered
    color: root.tone === "active" ? Colors.primaryText : (root.tone === "error" ? Colors.error : (hover.hovered ? Colors.primary : Colors.surfaceText))
  }

  NPressFeedback {
    id: press
    scaleTarget: root
  }

  HoverHandler {
    id: hover
    enabled: root.available
    cursorShape: Qt.PointingHandCursor
    onHoveredChanged: {
      if (root.tooltip === "")
        return;
      if (hovered)
        TooltipService.show(root, root.tooltip);
      else
        TooltipService.hide();
    }
  }
  TapHandler {
    enabled: root.available
    onTapped: {
      press.trigger();
      root.tapped();
    }
  }
}
