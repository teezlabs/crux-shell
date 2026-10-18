import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Commons
import qs.Widgets
import qs.Modules.Bar.Extras
import qs.Services

// System tray: pinned items stay inline, the rest live in a drawer that slides along the bar (docs/design-notes.md, "The tray drawer").
Item {
  id: root

  property var screen: null
  property string section: ""
  property int sectionWidgetIndex: -1
  property bool vertical: false
  property bool invertChamfer: false
  property var widgetData: ({})

  readonly property string screenName: root.screen ? root.screen.name : ""
  readonly property bool drawerEnabled: root.widgetData.drawer !== undefined ? root.widgetData.drawer : true
  readonly property bool hidePassive: root.widgetData.hidePassive !== undefined ? root.widgetData.hidePassive : false
  readonly property var pinned: root.widgetData.pinned || []

  readonly property var rawItems: SystemTray.items && SystemTray.items.values ? SystemTray.items.values : []
  readonly property var allItems: {
    const hide = root.hidePassive;
    return root.rawItems.filter(i => i && !(hide && i.status === SystemTray.Passive));
  }
  // Split inline, not via TrayModel: a binding that calls into a singleton doesn't re-run reliably (docs/qml-gotchas.md).
  readonly property var inlineItems: {
    if (!root.drawerEnabled)
      return root.allItems;
    const pins = root.pinned;
    return root.allItems.filter(i => pins.indexOf(TrayModel.key(i)) !== -1);
  }
  readonly property var drawerItems: {
    if (!root.drawerEnabled)
      return [];
    const pins = root.pinned;
    return root.allItems.filter(i => pins.indexOf(TrayModel.key(i)) === -1);
  }

  readonly property bool hasDrawer: root.drawerEnabled && root.drawerItems.length > 0

  property bool expanded: false
  property int autoCollapseMs: 5000

  readonly property int cell: 24

  // Hover holds the drawer open; leaving restarts the countdown, because toggling running resets a Timer.
  HoverHandler {
    id: hover
  }

  Timer {
    interval: root.autoCollapseMs
    // An open DBusMenu would be left anchored to nothing if the drawer collapsed under it.
    running: root.expanded && !hover.hovered && trayMenu.menuHandle === null
    onTriggered: root.expanded = false
  }

  // Collapse once nothing is left in the drawer, or it can't be closed.
  onDrawerItemsChanged: {
    if (root.drawerItems.length === 0)
      root.expanded = false;
  }

  implicitWidth: module.implicitWidth
  implicitHeight: module.implicitHeight
  width: implicitWidth
  height: implicitHeight
  visible: root.inlineItems.length > 0 || root.hasDrawer

  QsMenuPopup {
    id: trayMenu
    targetScreen: root.screen
    onPinToggled: TrayModel.togglePin(root.screenName, root.section, root.sectionWidgetIndex, trayMenu.trayItem)
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
        model: root.inlineItems

        delegate: TrayCell {
          required property var modelData
          item: modelData
          menu: trayMenu
          cell: root.cell
          pinned: true
          widgetScreenName: root.screenName
          widgetSection: root.section
          widgetIndex: root.sectionWidgetIndex
          pinnable: root.drawerEnabled
        }
      }

      // Collapses along the bar's axis, so the widget shrinks back into itself.
      Item {
        id: drawer
        clip: true
        visible: width > 0 && height > 0

        readonly property real openWidth: root.vertical ? root.cell : drawerGrid.implicitWidth + 2
        readonly property real openHeight: root.vertical ? drawerGrid.implicitHeight + 2 : root.cell

        width: root.expanded ? openWidth : 0
        height: root.expanded ? openHeight : (root.vertical ? 0 : root.cell)

        Behavior on width {
          NumberAnimation {
            duration: Tokens.durationPanel
            easing.type: Tokens.easingPanel
          }
        }
        Behavior on height {
          NumberAnimation {
            duration: Tokens.durationPanel
            easing.type: Tokens.easingPanel
          }
        }

        Grid {
          id: drawerGrid
          // Pinned to the chevron end so icons are revealed from under it.
          x: root.vertical ? 0 : drawer.width - width
          y: root.vertical ? drawer.height - height : 0
          flow: root.vertical ? Grid.TopToBottom : Grid.LeftToRight
          rows: root.vertical ? 1000 : 1
          columns: root.vertical ? 1 : 1000
          spacing: 2
          leftPadding: root.vertical ? 0 : 2
          topPadding: root.vertical ? 2 : 0

          Repeater {
            model: root.drawerItems

            delegate: TrayCell {
              required property var modelData
              item: modelData
              menu: trayMenu
              cell: root.cell
              pinned: false
              widgetScreenName: root.screenName
              widgetSection: root.section
              widgetIndex: root.sectionWidgetIndex
              pinnable: root.drawerEnabled
              onActioned: root.expanded = false
            }
          }
        }
      }

      // Points outward to open, back toward the pinned icons to close.
      Item {
        id: chevron
        width: root.cell
        height: root.cell
        visible: root.hasDrawer

        NIcon {
          anchors.centerIn: parent
          width: 14
          height: 14
          source: Quickshell.iconPath(root.expanded ? TrayModel.collapseIcon(root.vertical) : TrayModel.expandIcon(root.vertical), "")
          color: root.expanded ? Colors.primary : Colors.surfaceTextMuted
        }

        HoverHandler {
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: root.expanded = !root.expanded
        }
      }
    }
  }
}
