import QtQuick
import qs.Commons
import qs.Services
import qs.Widgets
import qs.Modules.Bar.Extras

// Caps/Num/Scroll lock indicator. capsLock/numLock come from Keyboard; scroll lock has no
// source on this hardware (not in Hyprland's JSON, no sysfs LED either) so it always shows "unknown", not a bug.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property bool invertChamfer: false

  readonly property bool capsLockOn: Keyboard.capsLock
  readonly property bool numLockOn: Keyboard.numLock

  readonly property bool showCaps: Settings.data.lockKeys.showCapsLock
  readonly property bool showNum: Settings.data.lockKeys.showNumLock
  readonly property bool showScroll: Settings.data.lockKeys.showScrollLock
  readonly property bool hideWhenOff: Settings.data.lockKeys.hideWhenOff

  readonly property bool _anyVisible: (showCaps && (!hideWhenOff || capsLockOn)) || (showNum && (!hideWhenOff || numLockOn)) || (showScroll && !hideWhenOff)

  visible: _anyVisible
  implicitWidth: visible ? module.implicitWidth : 0
  implicitHeight: Tokens.barCell
  width: implicitWidth
  height: implicitHeight

  Component.onCompleted: Keyboard.lockKeyWatchers++
  Component.onDestruction: Keyboard.lockKeyWatchers--

  BarModule {
    id: module
    invertChamfer: root.invertChamfer
    vertical: root.vertical
    topPadding: 8
    bottomPadding: 8

    Row {
      visible: !root.vertical
      spacing: 6

      NText {
        visible: root.showCaps && (!root.hideWhenOff || root.capsLockOn)
        text: "C"
        size: NText.Size.Label
        font.weight: Font.DemiBold
        color: root.capsLockOn ? Colors.primary : Colors.alpha(Colors.surfaceTextMuted, 0.35)
      }
      NText {
        visible: root.showNum && (!root.hideWhenOff || root.numLockOn)
        text: "N"
        size: NText.Size.Label
        font.weight: Font.DemiBold
        color: root.numLockOn ? Colors.primary : Colors.alpha(Colors.surfaceTextMuted, 0.35)
      }
      NText {
        visible: root.showScroll && !root.hideWhenOff
        text: "S"
        size: NText.Size.Label
        font.weight: Font.DemiBold
        color: Colors.alpha(Colors.surfaceTextMuted, 0.2)
      }
    }

    Column {
      visible: root.vertical
      spacing: 2

      NText {
        visible: root.showCaps && (!root.hideWhenOff || root.capsLockOn)
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: "C"
        size: NText.Size.LabelXs
        font.weight: Font.DemiBold
        color: root.capsLockOn ? Colors.primary : Colors.alpha(Colors.surfaceTextMuted, 0.35)
      }
      NText {
        visible: root.showNum && (!root.hideWhenOff || root.numLockOn)
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: "N"
        size: NText.Size.LabelXs
        font.weight: Font.DemiBold
        color: root.numLockOn ? Colors.primary : Colors.alpha(Colors.surfaceTextMuted, 0.35)
      }
      NText {
        visible: root.showScroll && !root.hideWhenOff
        width: 24
        horizontalAlignment: Text.AlignHCenter
        text: "S"
        size: NText.Size.LabelXs
        font.weight: Font.DemiBold
        color: Colors.alpha(Colors.surfaceTextMuted, 0.2)
      }
    }
  }

  HoverHandler {
    cursorShape: Qt.PointingHandCursor
    onHoveredChanged: {
      if (hovered) {
        var parts = ["Caps Lock: " + (root.capsLockOn ? "on" : "off"), "Num Lock: " + (root.numLockOn ? "on" : "off")];
        if (root.showScroll)
          parts.push("Scroll Lock: unavailable on this system");
        TooltipService.show(root, parts.join("\n"));
      } else {
        TooltipService.hide();
      }
    }
  }
}
