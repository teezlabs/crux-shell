import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Commons
import qs.Modules.Bar.Extras
import qs.Widgets

// Real systray protocol integration (Quickshell.Services.SystemTray), real
// per-app icons (not spec §3's abstract rotated-square glyph — confirmed
// deliberate). Most tray items that matter (NetworkManager, Bluetooth
// applets) are "onlyMenu" — real functionality lives behind their DBusMenu,
// rendered here via QsMenuPopup (crux-styled, not the native QMenu),
// not a bare activate().
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property bool invertChamfer: false

  readonly property var trayItems: SystemTray.items && SystemTray.items.values ? SystemTray.items.values : []

  implicitWidth: module.implicitWidth
  implicitHeight: module.implicitHeight
  width: implicitWidth
  height: implicitHeight
  visible: trayItems.length > 0

  QsMenuPopup {
    id: trayMenu
    targetScreen: root.screen
  }

  BarModule {
    id: module
    vertical: root.vertical
    invertChamfer: root.invertChamfer
    leftPadding: 6
    rightPadding: 6
    topPadding: 6
    bottomPadding: 6

    Grid {
      flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
      rows: root.vertical ? 1000 : 1
      columns: root.vertical ? 1 : 1000
      spacing: 2

      Repeater {
        model: root.trayItems

        delegate: Item {
          id: trayCell
          required property var modelData
          readonly property bool attention: modelData && modelData.status === SystemTray.NeedsAttention
          width: 24
          height: 24

          Rectangle {
            visible: trayCell.attention
            anchors.fill: parent
            anchors.margins: 1
            color: "transparent"
            border.color: Color.tertiary
            border.width: 1
          }

          NIcon {
            anchors.centerIn: parent
            anchors.margins: 4
            width: 16
            height: 16
            asynchronous: true
            colorize: false
            source: trayCell.modelData ? trayCell.modelData.icon : ""
          }

          function openMenu() {
            var pos = trayCell.mapToItem(null, 0, trayCell.height);
            trayMenu.anchorPos = Qt.point(pos.x + Settings.data.bar.floatMargin, pos.y + Settings.data.bar.floatMargin);
            trayMenu.menuHandle = trayCell.modelData.menu;
          }

          HoverHandler {
            cursorShape: Qt.PointingHandCursor
          }

          TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: {
              if (trayCell.modelData.onlyMenu && trayCell.modelData.hasMenu)
                trayCell.openMenu();
              else
                trayCell.modelData.activate();
            }
          }
          TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: {
              if (trayCell.modelData.hasMenu)
                trayCell.openMenu();
              else if (trayCell.modelData.secondaryActivate)
                trayCell.modelData.secondaryActivate();
            }
          }
        }
      }
    }
  }
}
