import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// Night light quick toggle: off -> on -> forced -> off.
CcCircleToggle {
  id: tile
  signal expandRequested(string which)

  active: NightLightService.enabled
  onTapped: NightLightService.cycle()

  NIcon {
    anchors.centerIn: parent
    width: 16
    height: 16
    iconName: "weather-clear-night-symbolic"
    color: tile.active ? Color.primaryContainerText : Color.surfaceText
  }
}
