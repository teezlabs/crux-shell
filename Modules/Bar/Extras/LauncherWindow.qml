import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

// App launcher popup. Uses Quickshell's built-in DesktopEntries singleton
// (DesktopEntries.applications.values) — the same proven data source
// noctalia's Modules/Panels/Launcher/Providers/ApplicationsProvider.qml
// uses — rather than scanning .desktop files by hand. Simple substring
// search rather than porting a fuzzy-match library; good enough to find an
// app by name fast.
PanelWindow {
  id: root

  property var targetScreen: null
  screen: targetScreen

  property string query: ""
  property int selectedIndex: 0

  readonly property var allApps: {
    var apps = typeof DesktopEntries !== "undefined" && DesktopEntries.applications ? DesktopEntries.applications.values : [];
    return apps.filter(function (a) {
      return a && !a.noDisplay && !a.hidden;
    });
  }

  readonly property var results: {
    var q = query.trim().toLowerCase();
    var list = allApps;
    if (q !== "") {
      list = allApps.filter(function (a) {
        var name = (a.name || "").toLowerCase();
        var generic = (a.genericName || "").toLowerCase();
        var comment = (a.comment || "").toLowerCase();
        return name.indexOf(q) !== -1 || generic.indexOf(q) !== -1 || comment.indexOf(q) !== -1;
      });
      list.sort(function (a, b) {
        var an = (a.name || "").toLowerCase();
        var bn = (b.name || "").toLowerCase();
        var aStarts = an.indexOf(q) === 0;
        var bStarts = bn.indexOf(q) === 0;
        if (aStarts !== bStarts)
          return aStarts ? -1 : 1;
        return an.localeCompare(bn);
      });
    } else {
      list = list.slice().sort(function (a, b) {
        return (a.name || "").toLowerCase().localeCompare((b.name || "").toLowerCase());
      });
    }
    return list.slice(0, 30);
  }

  onQueryChanged: selectedIndex = 0
  onResultsChanged: if (selectedIndex >= results.length)
    selectedIndex = Math.max(0, results.length - 1)

  function launch(app) {
    if (!app)
      return;
    root.visible = false;
    query = "";
    Qt.callLater(function () {
      if (app.execute) {
        app.execute();
      } else if (app.command && app.command.length > 0) {
        Quickshell.execDetached(app.command);
      }
    });
  }

  function toggle() {
    visible = !visible;
    if (visible) {
      query = "";
      selectedIndex = 0;
      Qt.callLater(function () {
        searchInput.forceActiveFocus();
      });
    }
  }

  IpcHandler {
    enabled: root.targetScreen === Quickshell.screens[0]
    target: "launcher"
    function toggle() {
      root.toggle();
    }
    function open() {
      if (!root.visible)
        root.toggle();
    }
    function close() {
      root.visible = false;
    }
  }

  visible: false
  color: "transparent"

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "crux-launcher"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  Shortcut {
    sequence: "Escape"
    enabled: root.visible
    onActivated: root.visible = false
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.visible = false
  }

  // Soft drop shadow behind the card, same treatment as the bar itself
  // (shell.qml) — depth against whatever's behind the popup.
  MultiEffect {
    anchors.fill: card
    source: card
    shadowEnabled: true
    shadowColor: Qt.rgba(0, 0, 0, 0.55)
    shadowBlur: 0.7
    shadowVerticalOffset: 3
    shadowHorizontalOffset: 0
  }

  Rectangle {
    id: card
    anchors.centerIn: parent
    width: 480
    height: Math.min(480, column.implicitHeight + 24)
    radius: Style.radiusXXS
    color: Color.mSurface
    border.color: Color.mOutline
    border.width: 1

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    ColumnLayout {
      id: column
      anchors.fill: parent
      anchors.margins: 12
      spacing: 8

      TextInput {
        id: searchInput
        Layout.fillWidth: true
        text: root.query
        onTextChanged: root.query = text
        color: Color.mOnSurface
        font.family: Settings.data.ui.fontFamily
        font.pixelSize: 16

        Rectangle {
          z: -1
          anchors.fill: parent
          anchors.margins: -8
          color: Color.mSurfaceVariant
          radius: Style.radiusXXS
        }

        Text {
          visible: searchInput.text === ""
          text: "Search apps…"
          color: Color.mOnSurfaceVariant
          font.family: Settings.data.ui.fontFamily
          font.pixelSize: 16
        }

        Keys.onDownPressed: root.selectedIndex = Math.min(root.results.length - 1, root.selectedIndex + 1)
        Keys.onUpPressed: root.selectedIndex = Math.max(0, root.selectedIndex - 1)
        Keys.onReturnPressed: root.launch(root.results[root.selectedIndex])
      }

      ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(400, contentHeight)
        clip: true
        model: root.results
        currentIndex: root.selectedIndex

        delegate: Item {
          id: rowItem
          required property var modelData
          required property int index
          width: ListView.view.width
          height: 32

          Rectangle {
            anchors.fill: parent
            radius: Style.radiusXXS
            color: rowItem.index === root.selectedIndex ? Color.mSurfaceVariant : "transparent"
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            Text {
              text: rowItem.modelData.name || ""
              color: Color.mOnSurface
              font.family: Settings.data.ui.fontFamily
              font.pixelSize: 13
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selectedIndex = rowItem.index
            onClicked: root.launch(rowItem.modelData)
          }
        }
      }
    }
  }
}
