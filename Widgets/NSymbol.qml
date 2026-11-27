import QtQuick
import qs.Commons

// A Material Symbols icon by name; `filled` eases the glyph between outline and solid.
Text {
  id: root

  property string name: ""
  property bool filled: false
  property real size: 18
  property int weight: 400
  property real _fill: root.filled ? 1 : 0

  Behavior on _fill {
    NumberAnimation {
      duration: Tokens.durationColor
      easing.type: Tokens.easingColor
    }
  }
  Behavior on color {
    ColorAnimation {
      duration: Tokens.durationColor
      easing.type: Tokens.easingColor
    }
  }

  text: Symbols.glyph(root.name)
  color: Colors.surfaceText
  font.family: Symbols.family
  font.pixelSize: root.size
  font.variableAxes: {
    "FILL": root._fill,
    "wght": root.weight
  }
  width: root.size
  height: root.size
  horizontalAlignment: Text.AlignHCenter
  verticalAlignment: Text.AlignVCenter
}
