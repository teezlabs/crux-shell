import QtQuick
import qs.Commons

// Glides a Flickable a fixed step per mouse-wheel notch; touchpads keep Qt's own kinetic scrolling.
WheelHandler {
  id: root

  required property Flickable flickable
  property real step: Tokens.scrollWheelStep

  function stop(): void {
    glide.stop();
  }

  function _clamp(y) {
    const top = root.flickable.originY;
    return Math.max(top, Math.min(top + root.flickable.contentHeight - root.flickable.height, y));
  }

  target: null
  acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
  onWheel: event => {
    // Touchpads scroll in phases; leave those to the Flickable so it keeps the inertia.
    if (event.phase !== Qt.NoScrollPhase || root.flickable.contentHeight <= root.flickable.height || event.angleDelta.y === 0) {
      event.accepted = false;
      return;
    }
    const from = glide.running ? glide.to : root.flickable.contentY;
    glide.to = root._clamp(from - event.angleDelta.y / 120 * root.step);
    glide.restart();
  }

  property NumberAnimation _glide: NumberAnimation {
    id: glide
    target: root.flickable
    property: "contentY"
    duration: Tokens.durationScrollGlide
    easing.type: Tokens.easingScrollGlide
  }
}
