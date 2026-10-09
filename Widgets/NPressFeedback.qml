import QtQuick
import qs.Commons

// Press acknowledgement for a control: a brief swell, and a light wash that
// fades out over it. Drop one inside the control, point scaleTarget at the
// item that should swell, and call trigger() from the TapHandler.
//
// The wash is surfaceText at low alpha, not white — on a light theme a
// white flash over a light surface is invisible, while the text tone is
// always the one color guaranteed to contrast with the surface under it.
Item {
  id: root

  anchors.fill: parent

  // The item that swells. Usually the control's own root; left unset, the
  // pop is skipped and only the wash plays.
  property Item scaleTarget: null
  // Match the host's own chamfer so the wash has the control's shape.
  property int chamferSize: Tokens.chamferIcon
  property bool invertChamfer: false

  property real _flash: 0

  function trigger(): void {
    if (root.scaleTarget)
      popAnim.restart();
    flashAnim.restart();
  }

  Chamfer {
    anchors.fill: parent
    chamferSize: root.chamferSize
    cutTopLeft: root.invertChamfer
    cutBottomRight: root.invertChamfer
    cutTopRight: !root.invertChamfer
    cutBottomLeft: !root.invertChamfer
    fillColor: Colors.alpha(Colors.surfaceText, root._flash)
    strokeColor: "transparent"
    // The wash is already an animation; easing its color as well would
    // fight the fade.
    animateColor: false
  }

  SequentialAnimation {
    id: popAnim
    NumberAnimation {
      target: root.scaleTarget
      property: "scale"
      to: Tokens.pressScale
      duration: Tokens.durationPressIn
      easing.type: Tokens.easingPressIn
    }
    NumberAnimation {
      target: root.scaleTarget
      property: "scale"
      to: 1.0
      duration: Tokens.durationPressOut
      easing.type: Tokens.easingPressOut
    }
  }

  NumberAnimation {
    id: flashAnim
    target: root
    property: "_flash"
    from: Tokens.flashOpacity
    to: 0
    duration: Tokens.durationFlash
    easing.type: Tokens.easingFlash
  }
}
