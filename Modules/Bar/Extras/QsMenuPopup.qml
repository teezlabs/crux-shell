import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons

// Custom-rendered replacement for QsMenuAnchor's native platform QMenu, restyled as ordinary chamfered rows.
// One level of real submenu support: hasChildren opens another instance of this component to the right, recursing if needed.
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

  // Icon can be a bare theme name (needs iconPath()) or already a path/URL — using iconPath() on the latter breaks the glyph.
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

  // Loaded by URL, not `QsMenuPopup { }` directly — QML rejects a component instantiating itself by type name.
  Loader {
    id: submenuLoader
    active: false
    source: "QsMenuPopup.qml"
    onLoaded: item.targetScreen = root.targetScreen
  }
}
