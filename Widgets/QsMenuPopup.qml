import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.Commons
import qs.Widgets

// Chamfered replacement for QsMenuAnchor's native QMenu; submenus open another instance to the right.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  // The QsMenuHandle to render: a tray item's menu or a submenu entry.
  property var menuHandle: null
  // Point in this window's coordinates to anchor the menu's top-left near.
  property point anchorPos: Qt.point(0, 0)
  // Optional footer row below the DBusMenu entries (the tray's pin/unpin). Empty hides it.
  property string pinLabel: ""
  property var trayItem: null

  signal pinToggled

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
    height: Math.min(480, list.contentHeight + 8) + (pinRow.visible ? pinRow.height + 5 : 0)

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutTopRight: true
      cutBottomLeft: true
      fillColor: Colors.alpha(Colors.surface, Tokens.panelOpacity)
      strokeColor: Colors.outline
      strokeWidth: Tokens.borderPanel
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ListView {
      id: list
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: pinRow.visible ? pinRow.top : parent.bottom
      anchors.margins: 4
      anchors.bottomMargin: pinRow.visible ? 1 : 4
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
          color: Colors.outlineVariant
        }

        Rectangle {
          visible: !row.modelData.isSeparator
          anchors.fill: parent
          color: rowHover.hovered && row.modelData.enabled ? Colors.surfaceContainerHigh : "transparent"
        }

        RowLayout {
          visible: !row.modelData.isSeparator
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 8

          // Check/radio state as a dot, filled when checked.
          Text {
            visible: row.modelData.buttonType !== QsMenuButtonType.None
            text: row.modelData.checkState === Qt.Checked ? "●" : "○"
            color: Colors.primary
            font.pixelSize: Tokens.captionSize
          }

          NIcon {
            visible: row.modelData.icon !== ""
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            source: root.resolveIcon(row.modelData.icon)
            color: Colors.surfaceText
          }

          NText {
            Layout.fillWidth: true
            text: row.modelData.text
            color: row.modelData.enabled ? Colors.surfaceText : Colors.disabledText
            size: NText.Size.BodySm
            elide: Text.ElideRight
          }

          Text {
            visible: row.modelData.hasChildren
            text: "›"
            color: Colors.labelText
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

    // Pin/unpin, divided off because it's crux's row, not the app's.
    Item {
      id: pinRow
      visible: root.pinLabel !== ""
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.margins: 4
      height: 30

      Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        height: 1
        color: Colors.outlineVariant
      }

      Rectangle {
        anchors.fill: parent
        anchors.topMargin: 1
        color: pinHover.hovered ? Colors.surfaceContainerHigh : "transparent"
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        NIcon {
          Layout.preferredWidth: 14
          Layout.preferredHeight: 14
          source: Quickshell.iconPath("pin-symbolic", "")
          color: Colors.primary
        }

        NText {
          Layout.fillWidth: true
          text: root.pinLabel
          color: Colors.primary
          size: NText.Size.BodySm
          elide: Text.ElideRight
        }
      }

      HoverHandler {
        id: pinHover
        cursorShape: Qt.PointingHandCursor
      }
      TapHandler {
        onTapped: {
          root.pinToggled();
          root.menuHandle = null;
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
