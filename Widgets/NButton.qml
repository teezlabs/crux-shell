import QtQuick
import qs.Commons

// Chamfered button.
//
// `neutral` is the default because it's what crux's panels actually use —
// a surface-toned cell with an outline and sentence-case body text.
// `accent` is the primary-filled call to action, `destructive` recolors off
// the error tone.
//
// Pointer handling is TapHandler/HoverHandler, never MouseArea — a
// MouseArea anywhere under the bar's drag TapHandler kills widget
// reordering outright (see the crux skill).
Item {
  id: root

  property string text: ""
  // "neutral" | "accent" | "destructive"
  property string variant: "neutral"
  property bool uppercase: false
  property int textSize: NText.Size.BodySm
  property bool invertChamfer: false
  property real horizontalPadding: 12
  // Extra content left of the label — an icon, a swatch, a status dot.
  default property alias content: leading.data

  signal clicked
  signal rightClicked

  readonly property bool accent: root.variant === "accent"
  readonly property bool destructive: root.variant === "destructive"

  readonly property color fill: {
    if (hover.hovered)
      return Colors.surfaceContainerHigh;
    return root.accent ? Colors.primaryContainer : Colors.surfaceContainer;
  }
  readonly property color stroke: {
    if (root.destructive)
      return Colors.alpha(Colors.error, Tokens.destructiveBorderAlpha);
    return root.accent ? Colors.primary : Colors.outline;
  }
  readonly property color labelColor: {
    if (root.destructive)
      return Colors.error;
    return root.accent ? Colors.primaryContainerText : Colors.surfaceText;
  }

  implicitHeight: 30
  implicitWidth: leading.implicitWidth + (leading.implicitWidth > 0 && label.implicitWidth > 0 ? 6 : 0) + label.implicitWidth + root.horizontalPadding * 2
  opacity: enabled ? 1 : 0.4

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferIcon
    cutTopLeft: root.invertChamfer
    cutBottomRight: root.invertChamfer
    cutTopRight: !root.invertChamfer
    cutBottomLeft: !root.invertChamfer
    fillColor: root.fill
    strokeColor: root.stroke
    strokeWidth: Tokens.borderModule
  }

  Row {
    anchors.centerIn: parent
    spacing: leading.implicitWidth > 0 && label.implicitWidth > 0 ? 6 : 0

    Item {
      id: leading
      anchors.verticalCenter: parent.verticalCenter
      implicitWidth: childrenRect.width
      implicitHeight: childrenRect.height
      width: implicitWidth
      height: implicitHeight
    }

    NText {
      id: label
      anchors.verticalCenter: parent.verticalCenter
      visible: root.text !== ""
      text: root.uppercase ? root.text.toUpperCase() : root.text
      size: root.textSize
      tracking: root.uppercase
      color: root.labelColor
    }
  }

  NPressFeedback {
    id: press
    scaleTarget: root
    chamferSize: Tokens.chamferIcon
    invertChamfer: root.invertChamfer
  }

  HoverHandler {
    id: hover
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
  }
  TapHandler {
    enabled: root.enabled
    acceptedButtons: Qt.LeftButton
    onTapped: {
      press.trigger();
      root.clicked();
    }
  }
  TapHandler {
    enabled: root.enabled
    acceptedButtons: Qt.RightButton
    onTapped: root.rightClicked()
  }
}
