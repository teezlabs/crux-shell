import QtQuick
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// Live FFT bars for whatever the default sink is playing. Capture is
// ref-counted in SpectrumService, so it only runs while this is on screen.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property bool invertChamfer: false

  // How many of the service's bands to draw. Fewer, wider bars read better
  // at bar height than all 32.
  property int barCount: 14
  property real barWidth: 2
  property real barGap: 2

  readonly property real span: root.barCount * root.barWidth + (root.barCount - 1) * root.barGap

  implicitWidth: module.implicitWidth
  implicitHeight: module.implicitHeight
  width: implicitWidth
  height: implicitHeight

  Component.onCompleted: SpectrumService.acquire()
  Component.onDestruction: SpectrumService.release()

  BarModule {
    id: module
    vertical: root.vertical
    invertChamfer: root.invertChamfer
    leftPadding: 8
    rightPadding: 8

    Item {
      width: root.vertical ? Tokens.barModuleHeight - 12 : root.span
      height: root.vertical ? root.span : 14
      anchors.verticalCenter: parent.verticalCenter

      Repeater {
        model: root.barCount

        delegate: Rectangle {
          id: bar
          required property int index

          // Spread the picked bands across the service's range so the
          // drawn bars still cover the whole spectrum, not just the bass.
          readonly property real level: {
            const v = SpectrumService.values;
            if (!v || v.length === 0)
              return 0;
            const i = Math.min(v.length - 1, Math.floor(bar.index * v.length / root.barCount));
            return Math.max(0, Math.min(1, v[i]));
          }

          color: Color.primary
          radius: 0

          x: root.vertical ? 0 : bar.index * (root.barWidth + root.barGap)
          y: root.vertical ? bar.index * (root.barWidth + root.barGap) : parent.height - height
          width: root.vertical ? Math.max(2, parent.width * bar.level) : root.barWidth
          height: root.vertical ? root.barWidth : Math.max(2, parent.height * bar.level)

          // Falls faster than it rises, so peaks read as peaks instead of
          // the whole row shimmering.
          Behavior on height {
            enabled: !root.vertical
            NumberAnimation {
              duration: Tokens.durationMeterFill
              easing.type: Tokens.easingMeterFill
            }
          }
          Behavior on width {
            enabled: root.vertical
            NumberAnimation {
              duration: Tokens.durationMeterFill
              easing.type: Tokens.easingMeterFill
            }
          }
        }
      }
    }
  }
}
