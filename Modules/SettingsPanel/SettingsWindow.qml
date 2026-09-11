import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import qs.Modules.ControlCenter
import qs.Modules.SettingsPanel.Controls
import qs.Widgets

// Settings panel: top-level tabs in the sidebar, some split into subtabs
// via NTabBar (Widgets/). New top-level tabs go in the `tabs` model below.
NPanelWindow {
  id: root

  popupName: "settings"

  readonly property string screenName: screen ? screen.name : ""
  property string activeTab: "general"

  // Fuzzy-search sidebar state. jumpSubTab is read once (onChanged, not a
  // binding) so later manual NTabBar clicks aren't fought by a stale hit.
  property string searchQuery: ""
  property string jumpSubTab: ""
  readonly property var searchResults: {
    if (root.searchQuery.trim() === "")
      return [];
    var hits = FuzzySort.go(root.searchQuery, searchIndex.entries, {
                               "keys": ["label", "keywords"],
                               "limit": 20,
                               "threshold": 0.3
                             });
    var out = [];
    for (var i = 0; i < hits.length; i++)
      out.push(hits[i].obj);
    return out;
  }

  function jumpToSearchHit(entry) {
    root.activeTab = entry.tab;
    if (entry.subTab)
      root.jumpSubTab = entry.subTab;
    root.searchQuery = "";
  }

  SettingsSearchIndex {
    id: searchIndex
  }

  readonly property var tabs: [
    {
      "id": "general",
      "label": "General"
    },
    {
      "id": "bar",
      "label": "Bar"
    },
    {
      "id": "appearance",
      "label": "Appearance"
    },
    {
      "id": "audio",
      "label": "Audio"
    },
    {
      "id": "hue",
      "label": "Hue"
    },
    {
      "id": "display",
      "label": "Display"
    },
    {
      "id": "systemMonitor",
      "label": "System Monitor"
    },
    {
      "id": "updates",
      "label": "Updates"
    },
    {
      "id": "wallpaper",
      "label": "Wallpaper"
    },
    {
      "id": "controlCenter",
      "label": "Control Center"
    },
    {
      "id": "launcher",
      "label": "Launcher"
    },
    {
      "id": "desktopWidgets",
      "label": "Desktop Widgets"
    },
    {
      "id": "osd",
      "label": "OSD"
    },
    {
      "id": "sessionMenu",
      "label": "Session Menu"
    },
    {
      "id": "lockScreen",
      "label": "Lock Screen"
    },
    {
      "id": "idle",
      "label": "Idle"
    },
    {
      "id": "notifications",
      "label": "Notifications"
    },
    {
      "id": "peripherals",
      "label": "Peripherals"
    },
    {
      "id": "connections",
      "label": "Connections"
    },
    {
      "id": "hooks",
      "label": "Hooks"
    },
    {
      "id": "plugins",
      "label": "Plugins"
    },
    {
      "id": "about",
      "label": "About"
    }
  ]

  // The one entry point deeper than open() — NPanelWindow's per-screen IPC
  // target forwards to it, and so does Popups.openTab.
  function openTab(tab) {
    activeTab = tab;
    visible = true;
  }

  Item {
    id: card
    anchors.centerIn: parent
    width: 860
    height: 620

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutTopRight: true
      cutBottomLeft: true
      fillColor: Color.alpha(Color.surface, Tokens.panelOpacity)
      strokeColor: Color.outline
      strokeWidth: Tokens.borderPanel
      shadow: true
      rimLight: true
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    RowLayout {
      anchors.fill: parent
      spacing: 0

      // ---------------- Sidebar ----------------      // 150px pinned with min and max, not preferredWidth alone: that's
      // only a hint, and next to a fillWidth sibling it has been seen to
      // let the sidebar claim nearly the whole card. See crux skill's SKILL.md.
      SettingsSidebar {
        Layout.preferredWidth: 150
        Layout.minimumWidth: 150
        Layout.maximumWidth: 150
        Layout.fillHeight: true

        tabs: root.tabs
        searchResults: root.searchResults
        searchQuery: root.searchQuery
        activeTab: root.activeTab
        onSearchQueryEdited: text => root.searchQuery = text
        onTabSelected: id => root.activeTab = id
        onJumpToSearchHit: entry => root.jumpToSearchHit(entry)
      }

      // ---------------- Content ----------------
      SettingsContent {
        Layout.fillWidth: true
        Layout.fillHeight: true

        tabs: root.tabs
        activeTab: root.activeTab
        jumpSubTab: root.jumpSubTab
        panelVisible: root.visible
        targetScreen: root.targetScreen
        screenName: root.screenName
      }
    }
  }
}
