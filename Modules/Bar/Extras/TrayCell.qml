import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.Commons
import qs.Widgets

// One tray icon, shared by the bar's inline row and the drawer's grid so
// both get the same activate/menu/pin behaviour from one place.
Item {
  id: root

  property var item: null
  // The QsMenuPopup to render this item's DBusMenu in — owned by whichever
  // surface hosts the cell, since the two live on different windows.
  property var menu: null
  property bool pinned: false
  property bool pinnable: true
  property string widgetScreenName: ""
  property string widgetSection: ""
  property int widgetIndex: -1
  property real cell: 24

  // Emitted after any action that should dismiss a drawer holding this cell.
  signal actioned

  readonly property bool attention: root.item && root.item.status === SystemTray.NeedsAttention

  width: root.cell
  height: root.cell

  function openMenu(): void {
    if (!root.menu || !root.item)
      return;
    const pos = root.mapToItem(null, 0, root.height);
    root.menu.anchorPos = Qt.point(pos.x + Settings.data.bar.floatMargin, pos.y + Settings.data.bar.floatMargin);
    root.menu.trayItem = root.item;
    root.menu.pinLabel = root.pinnable ? (root.pinned ? "Unpin from bar" : "Pin to bar") : "";
    root.menu.menuHandle = root.item.menu;
  }

  function togglePin(): void {
    TrayModel.togglePin(root.widgetScreenName, root.widgetSection, root.widgetIndex, root.item);
    root.actioned();
  }

  Rectangle {
    visible: root.attention
    anchors.fill: parent
    anchors.margins: 1
    color: "transparent"
    border.color: Color.tertiary
    border.width: 1
  }

  NIcon {
    anchors.centerIn: parent
    width: Math.round(root.cell * 0.67)
    height: Math.round(root.cell * 0.67)
    asynchronous: true
    colorize: false
    source: root.item ? root.item.icon : ""
  }

  HoverHandler {
    id: hover
    cursorShape: Qt.PointingHandCursor
    onHoveredChanged: {
      if (hovered)
        TooltipService.show(root, TrayModel.label(root.item));
      else
        TooltipService.hide();
    }
  }

  TapHandler {
    acceptedButtons: Qt.LeftButton
    onTapped: {
      if (!root.item)
        return;
      if (root.item.onlyMenu && root.item.hasMenu)
        root.openMenu();
      else
        root.item.activate();
      TooltipService.hideImmediately();
      root.actioned();
    }
  }
  TapHandler {
    acceptedButtons: Qt.RightButton
    onTapped: {
      if (!root.item)
        return;
      if (root.item.hasMenu)
        root.openMenu();
      else if (root.item.secondaryActivate)
        root.item.secondaryActivate();
    }
  }
  TapHandler {
    acceptedButtons: Qt.MiddleButton
    enabled: root.pinnable
    onTapped: root.togglePin()
  }
}
