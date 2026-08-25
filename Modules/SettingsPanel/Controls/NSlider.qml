import QtQuick
import qs.Commons

// Styled slider — flat accent-filled track + circular thumb, replacing the
// native QtQuick.Controls Slider (unstyled OS-theme chrome) used everywhere
// in the settings panel before. Modeled on noctalia's NSlider look, minus
// its NLabel/reset-button/I18n plumbing which crux doesn't have.
Item {
  id: root

  property real from: 0
  property real to: 1
  property real value: 0
  property real stepSize: 0
  signal moved(real value)

  implicitWidth: 200
  implicitHeight: 18

  readonly property real _ratio: root.to > root.from ? Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from))) : 0

  function _setFromX(x) {
    var ratio = Math.max(0, Math.min(1, x / root.width));
    var raw = root.from + ratio * (root.to - root.from);
    if (root.stepSize > 0)
      raw = Math.round(raw / root.stepSize) * root.stepSize;
    raw = Math.max(root.from, Math.min(root.to, raw));
    root.value = raw;
    root.moved(raw);
  }

  Rectangle {
    id: track
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 4
    radius: 2
    color: Color.mSurfaceVariant
    border.color: Color.mOutline
    border.width: 1

    Rectangle {
      width: parent.width * root._ratio
      height: parent.height
      radius: 2
      color: Color.mPrimary
    }
  }

  Rectangle {
    id: thumb
    width: 14
    height: 14
    radius: 7
    anchors.verticalCenter: parent.verticalCenter
    x: root._ratio * (root.width - width)
    color: Color.mPrimary
    border.color: Color.mOnPrimary
    border.width: 1
  }

  MouseArea {
    anchors.fill: parent
    anchors.margins: -4
    cursorShape: Qt.PointingHandCursor
    onPressed: mouse => root._setFromX(mouse.x - 4)
    onPositionChanged: mouse => {
      if (pressed)
        root._setFromX(mouse.x - 4);
    }
  }
}
