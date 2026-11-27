import QtQuick
import qs.Commons

// Chamfered toggle: primaryContainer fill and primary border when on, sliding chamfered thumb.
Item {
  id: root

  property bool checked: false
  signal toggled(bool checked)

  implicitWidth: 36
  implicitHeight: 20

  Chamfer {
    anchors.fill: parent
    chamferSize: Tokens.chamferIcon
    cutTopRight: true
    cutBottomLeft: true
    fillColor: root.checked ? Colors.primaryContainer : Colors.surfaceContainerHigh
    strokeColor: root.checked ? Colors.primary : Colors.outline
    strokeWidth: Tokens.borderModule
  }

  // Square thumb cut on the corner facing the track's cut, so it follows whichever side it sits on.
  Chamfer {
    id: thumb
    readonly property real inset: 3
    width: parent.height - inset * 2
    height: parent.height - inset * 2
    anchors.verticalCenter: parent.verticalCenter
    x: root.checked ? parent.width - width - inset : inset
    // The track's cut less the inset x (2 - sqrt 2), so the two cuts run parallel.
    chamferSize: Tokens.chamferIcon - inset * (2 - Math.SQRT2)
    cutTopRight: thumb.x > (root.width - thumb.width) / 2
    cutBottomLeft: !thumb.cutTopRight
    fillColor: root.checked ? Colors.primary : Colors.labelText

    Behavior on x {
      NumberAnimation {
        duration: Tokens.durationPanel
        easing.type: Tokens.easingPanel
      }
    }
  }

  HoverHandler {
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    onTapped: root.toggled(!root.checked)
  }
}
