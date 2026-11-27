import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.ControlCenter
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Every tab binds eagerly and is shown by visible, so a warning-free boot covers all of them.
ColumnLayout {
  id: panel

  // Supplied by SettingsWindow.
  property var tabs: []
  property string activeTab: ""
  property string jumpSubTab: ""
  property var targetScreen: null
  property string screenName: ""

  readonly property var activeTabInfo: panel.tabs.find(t => t.id === panel.activeTab) || {}

  signal navigate(string tab, string subTab)
  signal closeRequested

  // Each tab's opening sub-tab, so a visit without a target starts on its first page again.
  property var _firstSubTabs: []
  Component.onCompleted: {
    const first = [];
    for (let i = 0; i < tabContentArea.children.length; i++)
      first.push(tabContentArea.children[i].subTab);
    panel._firstSubTabs = first;
  }
  onActiveTabChanged: {
    if (panel.jumpSubTab !== "")
      return;
    for (let i = 0; i < tabContentArea.children.length; i++) {
      const tab = tabContentArea.children[i];
      if (panel._firstSubTabs[i] !== undefined)
        tab.subTab = panel._firstSubTabs[i];
    }
  }

  Layout.margins: 16
  spacing: 12

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
      Layout.fillWidth: true
      spacing: Tokens.spaceLg

      // Icon tile: the tab's sidebar icon at heading size.
      Item {
        Layout.preferredWidth: 44
        Layout.preferredHeight: 44
        Layout.alignment: Qt.AlignTop

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferModule
          cutTopRight: true
          cutBottomLeft: true
          fillColor: Colors.alpha(Colors.primary, 0.14)
          strokeColor: Colors.alpha(Colors.primary, 0.45)
          strokeWidth: Tokens.borderModule
        }

        NIcon {
          anchors.centerIn: parent
          width: 22
          height: 22
          iconName: panel.activeTabInfo.icon || ""
          color: Colors.primary
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: Tokens.spaceXs

        NText {
          text: panel.activeTabInfo.label || ""
          color: Colors.surfaceText
          size: NText.Size.Title
          Layout.fillWidth: true
        }

        NText {
          visible: text !== ""
          text: panel.activeTabInfo.description || ""
          color: Colors.labelText
          size: NText.Size.BodySm
          Layout.fillWidth: true
        }
      }

      // Chamfered close tile with a drawn X.
      Item {
        id: closeBtn
        width: 26
        height: 26
        Layout.alignment: Qt.AlignTop

        Chamfer {
          anchors.fill: parent
          chamferSize: Tokens.chamferIcon
          cutTopRight: true
          cutBottomLeft: true
          fillColor: closeHover.hovered ? Colors.alpha(Colors.error, 0.16) : "transparent"
          strokeColor: Colors.alpha(Colors.error, closeHover.hovered ? 0.7 : Tokens.destructiveBorderAlpha)
          strokeWidth: Tokens.borderModule
        }

        Canvas {
          id: closeGlyph
          anchors.centerIn: parent
          width: 10
          height: 10
          readonly property color strokeColor: closeHover.hovered ? Colors.error : Colors.surfaceTextMuted
          onStrokeColorChanged: requestPaint()
          onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = strokeColor;
            ctx.lineWidth = 1.6;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(width, height);
            ctx.moveTo(width, 0);
            ctx.lineTo(0, height);
            ctx.stroke();
          }
        }

        HoverHandler {
          id: closeHover
          cursorShape: Qt.PointingHandCursor
        }
        TapHandler {
          onTapped: panel.closeRequested()
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: Tokens.borderDivider
      color: Colors.surfaceContainerHigh
    }
  }

  Item {
    id: tabContentArea
    Layout.fillWidth: true
    Layout.fillHeight: true
    // Defensive: clips tabs taller than the card.
    clip: true

    HomeTab {
      anchors.fill: parent
      visible: panel.activeTab === "home"
      onNavigate: (tab, subTab) => panel.navigate(tab, subTab)
    }

    GeneralTab {
      anchors.fill: parent
      visible: panel.activeTab === "general"
      initialSubTab: panel.activeTab === "general" ? panel.jumpSubTab : ""
    }

    BarTab {
      anchors.fill: parent
      visible: panel.activeTab === "bar"
      screenName: panel.screenName
      initialSubTab: panel.activeTab === "bar" ? panel.jumpSubTab : ""
    }

    AppearanceTab {
      anchors.fill: parent
      visible: panel.activeTab === "appearance"
      initialSubTab: panel.activeTab === "appearance" ? panel.jumpSubTab : ""
    }

    AudioTab {
      anchors.fill: parent
      visible: panel.activeTab === "audio"
    }

    HueTab {
      anchors.fill: parent
      visible: panel.activeTab === "hue"
    }

    DisplayTab {
      anchors.fill: parent
      visible: panel.activeTab === "display"
      initialSubTab: panel.activeTab === "display" ? panel.jumpSubTab : ""
    }

    SystemMonitorTab {
      anchors.fill: parent
      visible: panel.activeTab === "systemMonitor"
    }
    UpdatesTab {
      anchors.fill: parent
      visible: panel.activeTab === "updates"
    }

    WallpaperTab {
      anchors.fill: parent
      visible: panel.activeTab === "wallpaper"
      initialSubTab: panel.activeTab === "wallpaper" ? panel.jumpSubTab : ""
    }

    ControlCenterTab {
      anchors.fill: parent
      visible: panel.activeTab === "controlCenter"
    }

    LauncherTab {
      anchors.fill: parent
      visible: panel.activeTab === "launcher"
    }

    DesktopWidgetsTab {
      anchors.fill: parent
      visible: panel.activeTab === "desktopWidgets"
    }

    LockScreenTab {
      anchors.fill: parent
      visible: panel.activeTab === "lockScreen"
      initialSubTab: panel.activeTab === "lockScreen" ? panel.jumpSubTab : ""
    }

    IdleTab {
      anchors.fill: parent
      visible: panel.activeTab === "idle"
      initialSubTab: panel.activeTab === "idle" ? panel.jumpSubTab : ""
    }

    NotificationsTab {
      anchors.fill: parent
      visible: panel.activeTab === "notifications"
      initialSubTab: panel.activeTab === "notifications" ? panel.jumpSubTab : ""
    }

    PeripheralsTab {
      anchors.fill: parent
      visible: panel.activeTab === "peripherals"
    }

    ConnectionsTab {
      anchors.fill: parent
      visible: panel.activeTab === "connections"
    }

    HooksTab {
      anchors.fill: parent
      visible: panel.activeTab === "hooks"
      targetScreen: panel.targetScreen
      initialSubTab: panel.activeTab === "hooks" ? panel.jumpSubTab : ""
    }

    PluginsTab {
      anchors.fill: parent
      visible: panel.activeTab === "plugins"
      initialSubTab: panel.activeTab === "plugins" ? panel.jumpSubTab : ""
    }

    AboutTab {
      anchors.fill: parent
      visible: panel.activeTab === "about"
    }
  }
}
