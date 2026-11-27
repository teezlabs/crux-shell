import QtQuick
import qs.Commons

// Alpha mask fading a Flickable's content at an edge that has more to scroll. Hidden; it only feeds a MultiEffect:
//   layer.enabled: fade.active
//   layer.effect: MultiEffect { maskEnabled: true; maskSource: fade; maskThresholdMin: 0.5; maskSpreadAtMin: 1 }
Rectangle {
  id: root

  required property Flickable flickable
  readonly property real _stop: Tokens.scrollFadeLength / Math.max(height, 1)
  property real topFade: root.flickable.contentHeight > root.flickable.height && !root.flickable.atYBeginning ? 1 : 0
  property real bottomFade: root.flickable.contentHeight > root.flickable.height && !root.flickable.atYEnd ? 1 : 0
  readonly property bool active: root.topFade > 0 || root.bottomFade > 0

  Behavior on topFade {
    NumberAnimation {
      duration: Tokens.durationColor
      easing.type: Tokens.easingColor
    }
  }
  Behavior on bottomFade {
    NumberAnimation {
      duration: Tokens.durationColor
      easing.type: Tokens.easingColor
    }
  }

  width: root.flickable.width
  height: root.flickable.height
  visible: false
  layer.enabled: true
  gradient: Gradient {
    GradientStop {
      position: 0
      color: Qt.rgba(0, 0, 0, 1 - root.topFade)
    }
    GradientStop {
      position: root._stop
      color: Qt.rgba(0, 0, 0, 1)
    }
    GradientStop {
      position: 1 - root._stop
      color: Qt.rgba(0, 0, 0, 1)
    }
    GradientStop {
      position: 1
      color: Qt.rgba(0, 0, 0, 1 - root.bottomFade)
    }
  }
}
