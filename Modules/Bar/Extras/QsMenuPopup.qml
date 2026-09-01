import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons

// Custom-rendered replacement for QsMenuAnchor's native platform QMenu
// (Tray.qml's right-click DBusMenu popup, and anything else that ends up
// showing a QsMenuHandle) — QsMenuAnchor.open() pops up the real OS-theme
// QMenu widget (Fusion/whatever style Qt picked), completely outside
// crux's own Chamfer/Color/Tokens design system with no way to restyle it.
// QsMenuOpener exposes the same menu as a plain list of QsMenuEntry
// objects (text/icon/isSeparator/enabled/checkState/hasChildren) that this
// renders as ordinary chamfered rows instead, matching every other popup
// in the app.
//
// One level of real submenu support: an entry with hasChildren opens a
// second instance of this same component, positioned to the right of the
// row that opened it (recursing further if a submenu itself has
// submenus) — most tray DBusMenus (Discord, NetworkManager, Bluetooth
// applets) are flat or one level deep, so this covers the real cases
// without building a generic infinite-nesting menu system.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  // The QsMenuHandle to render (trayItem.menu, or a submenu entry's own
  // handle — QsMenuEntry extends QsMenuHandle, see QsMenuOpener's own
  // property type).
  property var menuHandle: null
  // Screen-local point (already in this window's own coordinate space,
  // e.g. via mapToItem(null, x, y) from the triggering row) to anchor the
  // menu's top-left near.
  property point anchorPos: Qt.point(0, 0)

  QsMenuOpener {
    id: opener
    menu: root.menuHandle
  }

  function close() {
    root.visible = false;
    if (submenuLoader.item)
      submenuLoader.item.close();
  }

  // A DBusMenu entry's icon can be a bare icon-theme name (needs
  // Quickshell.iconPath() to resolve through the theme) or an absolute
  // file path / already-a-URL straight from the app (Quickshell.iconPath()
  // would wrongly try to look that up as a theme name and fail, rendering
  // as a broken-image glyph — confirmed real bug via screenshot). Use it
  // directly whenever it already looks like a path or URL.
  function resolveIcon(icon) {
    if (!icon)
      return "";
    if (icon.indexOf("/") === 0 || icon.indexOf("file://") === 0 || icon.indexOf("http://") === 0 || icon.indexOf("https://") === 0 || icon.indexOf("image://") === 0)
      return icon;
    return Quickshell.iconPath(icon, "");
  }

  visible: root.menuHandle !== null
  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-qsmenu"
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  MouseArea {
    anchors.fill: parent
    onClicked: root.menuHandle = null
  }

  Item {
    id: card
    x: Math.max(4, Math.min(root.anchorPos.x, root.width - width - 4))
    y: Math.max(4, Math.min(root.anchorPos.y, root.height - height - 4))
    width: 220
    height: Math.min(480, list.contentHeight + 8)

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutTopRight: true
      cutBottomLeft: true
      fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
      strokeColor: Color.outline
      strokeWidth: Tokens.borderPanel
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ListView {
      id: list
      anchors.fill: parent
      anchors.margins: 4
      clip: true
      interactive: contentHeight > height
      model: opener.children

      delegate: Item {
        id: row
        required property var modelData
        width: ListView.view.width
        height: modelData.isSeparator ? 9 : 30

        Rectangle {
          visible: row.modelData.isSeparator
          anchors.verticalCenter: parent.verticalCenter
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: 6
          anchors.rightMargin: 6
          height: 1
          color: Color.outlineVariant
        }

        Rectangle {
          visible: !row.modelData.isSeparator
          anchors.fill: parent
          color: rowHover.hovered && row.modelData.enabled ? Color.surfaceContainerHigh : "transparent"
        }

        RowLayout {
          visible: !row.modelData.isSeparator
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 8

          // Check/radio state — a plain dot for either type, filled when
          // checked. Real DBusMenu state, not decorative.
          Text {
            visible: row.modelData.buttonType !== QsMenuButtonType.None
            text: row.modelData.checkState === Qt.Checked ? "●" : "○"
            color: Color.primary
            font.pixelSize: Tokens.captionSize
          }

          IconImage {
            visible: row.modelData.icon !== ""
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            source: root.resolveIcon(row.modelData.icon)
          }

          Text {
            Layout.fillWidth: true
            text: row.modelData.text
            color: row.modelData.enabled ? Color.surfaceText : Color.disabledText
            font.family: Tokens.fontFamily
            font.pixelSize: Tokens.bodySmSize
            elide: Text.ElideRight
          }

          Text {
            visible: row.modelData.hasChildren
            text: "›"
            color: Color.labelText
            font.pixelSize: Tokens.bodySmSize
          }
        }

        HoverHandler {
          id: rowHover
          enabled: !row.modelData.isSeparator && row.modelData.enabled
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          enabled: !row.modelData.isSeparator && row.modelData.enabled
          onTapped: {
            if (row.modelData.hasChildren) {
              var pos = row.mapToItem(root, row.width, 0);
              submenuLoader.active = false;
              submenuLoader.active = true;
              submenuLoader.item.menuHandle = row.modelData;
              submenuLoader.item.anchorPos = pos;
            } else {
              row.modelData.triggered();
              root.menuHandle = null;
            }
          }
        }
      }
    }
  }

  // Loaded by URL rather than as `QsMenuPopup { ... }` directly — QML
  // rejects a component instantiating itself by type name from within its
  // own definition ("QsMenuPopup is instantiated recursively"), but a
  // Loader resolving the same file by source URL is a dynamic load, not a
  // static self-reference, and works fine.
  Loader {
    id: submenuLoader
    active: false
    source: "QsMenuPopup.qml"
    onLoaded: item.targetScreen = root.targetScreen
  }
}
