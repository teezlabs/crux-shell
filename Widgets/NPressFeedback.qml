import QtQuick
import qs.Commons

// Press feedback: a brief swell plus a fading wash. Point scaleTarget at the item and call trigger().
// The wash is surfaceText, not white, so it shows on light themes too.
Item {
  id: root

  anchors.fill: parent

  // Unset skips the swell and plays only the wash.
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
    // The wash already animates; easing its colour would fight the fade.
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
