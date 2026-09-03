import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.Modules.Bar.Extras
import qs.Commons
import qs.Widgets

// Battery %/charging state via UPower.displayDevice. Auto-hides if !isPresent. Click opens the battery popup via PopupHost's IPC target.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false

  readonly property var device: UPower.displayDevice
  readonly property bool present: !!device && device.isPresent === true
  readonly property int percent: present ? Math.round((device.percentage || 0) * 100) : 0
  readonly property bool charging: present && device.state === UPowerDeviceState.Charging
  readonly property bool pluggedIn: present && (device.state === UPowerDeviceState.FullyCharged || device.state === UPowerDeviceState.PendingCharge)
  readonly property bool low: present && !charging && !pluggedIn && percent <= Settings.data.battery.lowThreshold && percent > Settings.data.battery.criticalThreshold
  readonly property bool critical: present && !charging && !pluggedIn && percent <= Settings.data.battery.criticalThreshold

  readonly property color statusColor: root.critical ? Color.error : (root.low ? Color.tertiary : (root.charging ? Color.primary : Color.surfaceText))

  function formatDuration(seconds) {
    if (!seconds || seconds <= 0)
      return "";
    var totalMin = Math.round(seconds / 60);
    var h = Math.floor(totalMin / 60);
    var m = totalMin % 60;
    if (h > 0)
      return h + "h " + m + "m";
    return m + "m";
  }

  readonly property string statusText: {
    if (!root.present)
      return "No battery detected";
    if (root.pluggedIn)
      return "Plugged in";
    if (root.charging && device.timeToFull > 0)
      return "Full in " + root.formatDuration(device.timeToFull);
    if (!root.charging && device.timeToEmpty > 0)
      return root.formatDuration(device.timeToEmpty) + " remaining";
    return root.charging ? "Charging" : "On battery";
  }

  // Not present on a desktop with no battery at all — collapse to nothing
  // rather than showing a permanently-empty/broken readout.
  visible: root.present
  opacity: root.present ? 1.0 : 0.0

  implicitWidth: root.present ? module.implicitWidth : 0
  implicitHeight: root.present ? module.implicitHeight : 0
  width: implicitWidth
  height: implicitHeight

  BarModule {
    id: module
    vertical: root.vertical
    topPadding: 8
    bottomPadding: 8

    Row {
      visible: !root.vertical
      spacing: 8

      SegMeter {
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: Tokens.meterBarBatteryCellHeight
        cellCount: Tokens.meterBarBatteryCells
        cellHeight: Tokens.meterBarBatteryCellHeight
        value: root.percent
        filledColor: root.statusColor
        emptyColor: Color.surfaceContainerHigh
      }

      StatText {
        label: "BAT"
        value: root.percent + "%"
        valueColor: root.statusColor
      }
    }

    Column {
      visible: root.vertical
      spacing: 8

      Column {
        width: 24
        NText {
          tracking: true
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: root.percent + "%"
          color: root.statusColor
          size: NText.Size.LabelXs
        }
        NText {
          tracking: true
          width: 24
          horizontalAlignment: Text.AlignHCenter
          text: "BAT"
          color: Color.labelText
          font.pixelSize: Tokens.labelXsSize - 1
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
      }
    }
  }

  HoverHandler {
    cursorShape: Qt.PointingHandCursor
    onHoveredChanged: {
      if (hovered)
        TooltipService.show(root, root.statusText);
      else
        TooltipService.hide();
    }
  }

  TapHandler {
    onTapped: {
      TooltipService.hideImmediately();
      var pos = root.mapToItem(null, 0, 0);
      Popups.openAt("battery", root.screen, pos.x, pos.y);
    }
  }

  onStatusTextChanged: if (TooltipService.anchorItem === root)
    TooltipService.text = root.statusText
}
