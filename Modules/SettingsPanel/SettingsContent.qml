import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Modules.ControlCenter
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Settings panel content pane. Every tab instantiates and binds eagerly
// and is shown by `visible` rather than loaded lazily — which is why a
// warning-free boot is real evidence that all of them are sound, not just
// whichever one was open.
ColumnLayout {
  id: panel

  // Supplied by SettingsWindow.
  property var tabs: []
  property string activeTab: ""
  property string jumpSubTab: ""
  // The window's own visible, renamed: a plain `visible` here would collide
  // with this item's.
  property bool panelVisible: false
  property var targetScreen: null
  property string screenName: ""

  Layout.margins: 16
  spacing: 12

  ColumnLayout {
    Layout.fillWidth: true
    spacing: 8

    RowLayout {
      Layout.fillWidth: true
      spacing: 10

      Rectangle {
        width: 3
        height: 16
        color: Colors.primary
      }

      NText {
        text: {
          for (var i = 0; i < panel.tabs.length; i++)
            if (panel.tabs[i].id === panel.activeTab)
              return panel.tabs[i].label;
          return "";
        }
        color: Colors.surfaceText
        size: NText.Size.BodyLg
        font.weight: Font.DemiBold
        Layout.fillWidth: true
      }

      // Chamfered close tile with a Canvas-drawn X — no font-glyph
      // dependency (same reasoning as every bar icon).
      Item {
        id: closeBtn
        width: 26
        height: 26

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
          onTapped: panel.panelVisible = false
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
    // Defensive: clips tabs taller than the card (see notes.md).
    clip: true

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
