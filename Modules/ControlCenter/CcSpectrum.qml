import QtQuick
import qs.Commons
import qs.Services

// Full-width FFT bars from SpectrumService; holds cava only while `running`.
Item {
  id: root

  property bool running: false
  property real barGap: 2

  implicitHeight: 28

  onRunningChanged: running ? SpectrumService.acquire() : SpectrumService.release()
  Component.onCompleted: if (running)
    SpectrumService.acquire()
  Component.onDestruction: if (running)
    SpectrumService.release()

  readonly property int bandCount: 32
  readonly property real barWidth: Math.max(1, (root.width - root.barGap * (root.bandCount - 1)) / root.bandCount)

  Repeater {
    model: root.bandCount

    delegate: Rectangle {
      id: bar
      required property int index
      readonly property real level: {
        const v = SpectrumService.values;
        return v && bar.index < v.length ? Math.max(0, Math.min(1, v[bar.index])) : 0;
      }

      x: bar.index * (root.barWidth + root.barGap)
      y: root.height - height
      width: root.barWidth
      height: Math.max(2, root.height * bar.level)
      color: bar.level > 0.02 ? Colors.primary : Colors.surfaceContainerHigh

      Behavior on height {
        NumberAnimation {
          duration: Tokens.durationMeterFill
          easing.type: Tokens.easingMeterFill
        }
      }
    }
  }
}
