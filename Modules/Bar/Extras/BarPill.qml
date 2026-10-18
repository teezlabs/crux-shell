import QtQuick
import qs.Commons
import qs.Widgets

// Icon cell that expands to reveal a label; forceOpen keeps it expanded regardless of hover.
Item {
  id: root

  property string label: ""
  property bool forceOpen: false
  property bool attention: false
  property bool vertical: false
  property bool invertChamfer: false
  // Labels are arbitrary text (SSIDs, device names) and the pill grows the bar, so it elides past this.
  property real maxLabelWidth: 110
  // Glyph content, same contract as BarIconButton.
  default property alias content: iconSlot.data

  signal tapped
  signal secondaryTapped

  readonly property bool revealed: root.label !== "" && (root.forceOpen || hover.hovered)
  readonly property int cell: Tokens.barCell
  readonly property int gap: 6
  readonly property real labelWidth: Math.min(labelText.implicitWidth, root.maxLabelWidth)

  implicitWidth: root.vertical ? root.cell : root.cell + (root.revealed ? root.labelWidth + root.gap + 4 : 0)
  implicitHeight: root.vertical ? root.cell + (root.revealed ? labelText.implicitHeight + root.gap : 0) : root.cell
  width: implicitWidth
  height: implicitHeight

  Behavior on implicitWidth {
    NumberAnimation {
      duration: Tokens.durationPanel
      easing.type: Tokens.easingPanel
    }
  }
  Behavior on implicitHeight {
    NumberAnimation {
      duration: Tokens.durationPanel
      easing.type: Tokens.easingPanel
    }
  }

  // In a grouped section the section draws the surface; this keeps only hover and the attention stroke.
  readonly property bool grouped: Settings.isLoaded && Settings.data.bar.groupSections

  Chamfer {
    anchors.fill: parent
    chamferSize: root.grouped ? Tokens.chamferGroupedCell : Tokens.chamferModule
    cutTopLeft: root.invertChamfer
    cutBottomRight: root.invertChamfer
    cutTopRight: !root.invertChamfer
    cutBottomLeft: !root.invertChamfer
    fillColor: root.grouped ? Colors.alpha(Colors.primary, hover.hovered ? 0.16 : 0) : Colors.alpha(hover.hovered ? Colors.surfaceContainerHigh : Colors.surfaceContainer, Tokens.barModuleAlpha)
    strokeColor: root.attention ? Colors.tertiary : Colors.outlineVariant
    strokeWidth: root.grouped && !root.attention ? 0 : Tokens.borderModule
  }

  Item {
    id: iconSlot
    width: root.cell
    height: root.cell
    x: 0
    y: 0
  }

  NText {
    id: labelText
    text: root.label
    width: root.labelWidth
    elide: Text.ElideRight
    size: NText.Size.LabelXs
    tracking: true
    color: Colors.surfaceTextMuted
    // Clipped by the parent while collapsing rather than popping out.
    visible: root.revealed
    opacity: root.revealed ? 1 : 0
    x: root.vertical ? (root.width - width) / 2 : root.cell + root.gap
    y: root.vertical ? root.cell : (root.height - height) / 2

    Behavior on opacity {
      NumberAnimation {
        duration: Tokens.durationOsdFade
        easing.type: Tokens.easingOsdFade
      }
    }
  }

  clip: true

  HoverHandler {
    id: hover
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: root.tapped()
  }
  TapHandler {
    acceptedButtons: Qt.RightButton
    onTapped: root.secondaryTapped()
  }
}
