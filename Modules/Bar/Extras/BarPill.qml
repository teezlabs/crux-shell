import QtQuick
import qs.Commons
import qs.Widgets

// Icon cell that expands to reveal a label, the way noctalia's bar pills
// do. Collapsed it's the same 32px chamfered cell BarIconButton draws;
// revealed it grows along the bar to show `label`.
//
// `forceOpen` keeps it out regardless of hover — for a widget that wants to
// stay expanded while whatever it reports is active.
//
// Animating implicitWidth/implicitHeight is what drives BarSection's
// resize: it sums each item's width/height and re-reads on their change
// signals, so a plain Behavior here is enough to make the section follow.
Item {
  id: root

  property string label: ""
  property bool forceOpen: false
  property bool attention: false
  property bool vertical: false
  property bool invertChamfer: false
  // A pill grows the bar, so its label can't be unbounded — an SSID or a
  // Bluetooth device name is arbitrary text. Past this it elides.
  property real maxLabelWidth: 110
  // Glyph content, same contract as BarIconButton.
  default property alias content: iconSlot.data

  signal tapped
  signal secondaryTapped

  readonly property bool revealed: root.label !== "" && (root.forceOpen || hover.hovered)
  readonly property int cell: 32
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

  // Same opacity source BarIconButton and BarModule read.
  readonly property real effectiveOpacity: Settings.data.bar.useSeparateOpacity ? Settings.data.bar.backgroundOpacity : Settings.data.theme.barOpacity

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferModule
    cutTopLeft: root.invertChamfer
    cutBottomRight: root.invertChamfer
    cutTopRight: !root.invertChamfer
    cutBottomLeft: !root.invertChamfer
    fillColor: Color.alpha(hover.hovered ? Color.surfaceContainerHigh : Color.surfaceContainer, root.effectiveOpacity)
    strokeColor: root.attention ? Color.tertiary : Color.outlineVariant
    strokeWidth: Tokens.borderModule
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
    color: Color.surfaceTextMuted
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
