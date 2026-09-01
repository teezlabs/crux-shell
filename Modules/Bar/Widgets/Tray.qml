import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Commons
import qs.Modules.Bar.Extras

// v2 spec §6.1/§3 Tray module: real systray protocol integration
// (Quickshell.Services.SystemTray). Spec §3's literal text calls for an
// abstract "8×8 rotated square" per item, but the user explicitly asked for
// real per-app tray icons instead — deliberate deviation, confirmed
// request. IconImage (Quickshell.Widgets) resolves each item's `icon`
// string through the icon theme the same way a taskbar would, rather than a
// plain Image (which can't resolve bare icon-theme names, only direct
// paths/URLs). tertiary-tinted ring when an item requests attention.
//
// Real interaction, not just activate(): most tray items that matter day to
// day (NetworkManager, Bluetooth applets) are "onlyMenu" — they don't do
// anything useful on a bare activate(), all their real functionality lives
// behind their DBusMenu (modelData.menu/hasMenu/onlyMenu). QsMenuPopup (a
// crux-styled Chamfer/Color/Tokens menu, not the native platform QMenu
// QsMenuAnchor.open() would show) renders that real menu — one shared
// instance for the whole tray, positioned per-cell via mapToItem.
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

          IconImage {
            anchors.centerIn: parent
            anchors.margins: 4
            width: 16
            height: 16
            asynchronous: true
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
