import QtQuick
import qs.Commons
import qs.Services
import qs.Modules.Popups
import qs.Widgets
import qs.Modules.Bar.Extras

// CPU%/RAM% readout from SystemStats. Click opens the systemStats popup hosted by PopupHost.qml.
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property bool invertChamfer: false

  readonly property int cpuPercent: Math.round(SystemStats.cpuPercent)
  readonly property int memPercent: Math.round(SystemStats.memPercent)
  readonly property bool cpuWarn: cpuPercent >= Settings.data.systemMonitor.cpuWarningThreshold
  readonly property bool memWarn: memPercent >= Settings.data.systemMonitor.memWarningThreshold

  Component.onCompleted: SystemStats.watchers++
  Component.onDestruction: SystemStats.watchers--

  implicitWidth: module.implicitWidth
  implicitHeight: module.implicitHeight
  width: implicitWidth
  height: implicitHeight

  BarModule {
    id: module
    invertChamfer: root.invertChamfer
    vertical: root.vertical
    topPadding: 8
    bottomPadding: 8

    Row {
      visible: !root.vertical
      spacing: 10

      StatText {
        label: "CPU"
        value: root.cpuPercent + "%"
        valueColor: root.cpuWarn ? Colors.error : Colors.surfaceText
      }

      Rectangle {
        width: 1
        height: 12
        color: Colors.surfaceContainerHigh
      }

      StatText {
        label: "RAM"
        value: root.memPercent + "%"
        valueColor: root.memWarn ? Colors.error : Colors.surfaceText
      }
    }

    Column {
      visible: root.vertical
      spacing: 8

      Column {
        width: 28
        NText {
          tracking: true
          width: 28
          horizontalAlignment: Text.AlignHCenter
          text: root.cpuPercent + "%"
          color: root.cpuWarn ? Colors.error : Colors.surfaceText
          size: NText.Size.LabelXs
        }
        NText {
          tracking: true
          width: 28
          horizontalAlignment: Text.AlignHCenter
          text: "CPU"
          color: Colors.labelText
          font.pixelSize: Tokens.labelXsSize - 1
          font.letterSpacing: Tokens.labelXsSize * Tokens.labelXsTracking
        }
      }

      Rectangle {
        width: 28
        height: 1
        color: Colors.surfaceContainerHigh
      }

      Column {
        width: 28
        NText {
          tracking: true
          width: 28
          horizontalAlignment: Text.AlignHCenter
          text: root.memPercent + "%"
          color: root.memWarn ? Colors.error : Colors.surfaceText
          size: NText.Size.LabelXs
        }
        NText {
          tracking: true
          width: 28
          horizontalAlignment: Text.AlignHCenter
          text: "RAM"
          color: Colors.labelText
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
        TooltipService.show(root, "CPU " + root.cpuPercent + "%  ·  RAM " + root.memPercent + "%");
      else
        TooltipService.hide();
    }
  }
  TapHandler {
    onTapped: {
      TooltipService.hideImmediately();
      var pos = root.mapToItem(null, 0, 0);
      Popups.openFrom("systemStats", root.screen, pos.x, pos.y, root.width, root.height);
    }
  }
  onCpuPercentChanged: if (TooltipService.anchorItem === root)
    TooltipService.text = "CPU " + root.cpuPercent + "%  ·  RAM " + root.memPercent + "%"
  onMemPercentChanged: if (TooltipService.anchorItem === root)
    TooltipService.text = "CPU " + root.cpuPercent + "%  ·  RAM " + root.memPercent + "%"
}
