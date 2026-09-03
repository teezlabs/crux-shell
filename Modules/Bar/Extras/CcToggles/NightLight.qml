import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.Commons
import qs.Modules.Bar.Extras

// Night light quick toggle: off -> on -> forced -> off.
CcCircleToggle {
  id: tile
  signal expandRequested(string which)

  active: NightLightService.enabled
  onTapped: NightLightService.cycle()

  IconImage {
    anchors.centerIn: parent
    width: 16
    height: 16
    source: Quickshell.iconPath("weather-clear-night-symbolic")
  }
}
