import QtQuick
import qs.Commons

// Chamfered text button. `outlined` swaps the filled treatment for a
// bordered one; `destructive` recolors both variants off the error tone.
//
// Pointer handling is TapHandler/HoverHandler, never MouseArea — a
// MouseArea anywhere under the bar's drag TapHandler kills widget
// reordering outright (see the crux skill).
Item {
  id: root

  property string text: ""
  property bool outlined: false
  property bool destructive: false
  property bool invertChamfer: false
  property real horizontalPadding: 14
  // Content sits alongside the label when set — an icon, a swatch, a dot.
  default property alias content: leading.data

  signal clicked
  signal rightClicked

  readonly property color accent: root.destructive ? Color.error : Color.primary
  readonly property color fill: {
    if (root.outlined)
      return hover.hovered ? Color.surfaceContainerHigh : "transparent";
    return hover.hovered ? Color.surfaceContainerHigh : Color.primaryContainer;
  }
  readonly property color labelColor: root.outlined ? root.accent : (root.destructive ? Color.error : Color.primaryContainerText)

  implicitHeight: 28
  implicitWidth: leading.implicitWidth + (leading.implicitWidth > 0 && label.implicitWidth > 0 ? 6 : 0) + label.implicitWidth + root.horizontalPadding * 2
  width: implicitWidth
  height: implicitHeight
  opacity: enabled ? 1.0 : 0.5

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferIcon
    cutTopLeft: root.invertChamfer
    cutBottomRight: root.invertChamfer
    cutTopRight: !root.invertChamfer
    cutBottomLeft: !root.invertChamfer
    fillColor: root.fill
    strokeColor: root.destructive ? Color.alpha(Color.error, Tokens.destructiveBorderAlpha) : (root.outlined ? Color.outline : root.accent)
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
      text: root.text.toUpperCase()
      size: NText.Size.LabelXs
      color: root.labelColor
    }
  }

  HoverHandler {
    id: hover
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    enabled: root.enabled
    acceptedButtons: Qt.LeftButton
    onTapped: root.clicked()
  }

  TapHandler {
    enabled: root.enabled
    acceptedButtons: Qt.RightButton
    onTapped: root.rightClicked()
  }
}
