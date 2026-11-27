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

// Settings panel; new top-level tabs go in the `tabs` model below.
NPanelWindow {
  id: root

  popupName: "settings"

  readonly property string screenName: screen ? screen.name : ""
  property string activeTab: "home"

  // Search state. jumpSubTab is applied on change so later tab clicks aren't fought by a stale hit.
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

  // The sub-tab is set first: SettingsContent resets a tab to its first page when it opens with none.
  function jumpToSearchHit(entry) {
    root.jumpSubTab = entry.subTab || "";
    root.activeTab = entry.tab;
    root.searchQuery = "";
  }

  SettingsSearchIndex {
    id: searchIndex
  }

  // A focused text field takes a typed "/" first, so this only fires outside one.
  Shortcut {
    sequence: "/"
    enabled: root.visible
    onActivated: sidebar.focusSearch()
  }

  // Sidebar order; a header is drawn wherever `section` changes.
  readonly property var tabs: [
    {
      "id": "home",
      "label": "Home",
      "section": "",
      "icon": "go-home",
      "description": "Your theme at a glance, quick switches and shortcuts"
    },
    {
      "id": "appearance",
      "label": "Appearance",
      "section": "Personalize",
      "icon": "draw-brush",
      "description": "Fonts, scale, window corners and color presets"
    },
    {
      "id": "wallpaper",
      "label": "Wallpaper",
      "section": "Personalize",
      "icon": "viewimage",
      "description": "Wallpaper library, Wallhaven, theme generation and transitions"
    },
    {
      "id": "bar",
      "label": "Bar",
      "section": "Personalize",
      "icon": "view-split-left-right",
      "description": "Position, size and look of the bar, and the widgets on it"
    },
    {
      "id": "desktopWidgets",
      "label": "Desktop Widgets",
      "section": "Personalize",
      "icon": "widget-alternatives",
      "description": "The weather and media cards on the desktop"
    },
    {
      "id": "controlCenter",
      "label": "Control Center",
      "section": "Shell",
      "icon": "dashboard-show",
      "description": "Quick toggles, weather and action tiles"
    },
    {
      "id": "launcher",
      "label": "Launcher",
      "section": "Shell",
      "icon": "view-grid",
      "description": "The app launcher and clipboard history"
    },
    {
      "id": "notifications",
      "label": "Notifications",
      "section": "Shell",
      "icon": "notifications",
      "description": "Popups, how long they stay, history and the OSD"
    },
    {
      "id": "audio",
      "label": "Audio",
      "section": "System",
      "icon": "audio-volume-high",
      "description": "Volume, output and input devices, and media"
    },
    {
      "id": "display",
      "label": "Display",
      "section": "System",
      "icon": "monitor",
      "description": "Brightness and night light"
    },
    {
      "id": "connections",
      "label": "Connections",
      "section": "System",
      "icon": "network-wireless",
      "description": "Saved Wi-Fi networks and Bluetooth"
    },
    {
      "id": "peripherals",
      "label": "Peripherals",
      "section": "System",
      "icon": "input-mouse",
      "description": "Keyboard, lock keys and VPN connections"
    },
    {
      "id": "hue",
      "label": "Hue",
      "section": "System",
      "icon": "brightness-high",
      "description": "The Hue bridge and the room the bar controls"
    },
    {
      "id": "systemMonitor",
      "label": "System Monitor",
      "section": "System",
      "icon": "office-chart-line",
      "description": "How often stats are sampled and when they turn to warnings"
    },
    {
      "id": "updates",
      "label": "Updates",
      "section": "System",
      "icon": "system-software-update",
      "description": "How updates are checked and the commands that run them"
    },
    {
      "id": "lockScreen",
      "label": "Lock Screen",
      "section": "Session",
      "icon": "system-lock-screen",
      "description": "Clock, wallpaper, status row and which monitors lock"
    },
    {
      "id": "idle",
      "label": "Power",
      "section": "Session",
      "icon": "battery-full",
      "description": "Idle timeouts, custom idle commands and the session menu"
    },
    {
      "id": "general",
      "label": "Input",
      "section": "Advanced",
      "icon": "input-keyboard",
      "description": "Clock format, scrolling and keybinds"
    },
    {
      "id": "hooks",
      "label": "Hooks",
      "section": "Advanced",
      "icon": "code-context",
      "description": "Commands that run when the shell does something"
    },
    {
      "id": "plugins",
      "label": "Plugins",
      "section": "Advanced",
      "icon": "plugins",
      "description": "Installed and discovered bar plugins and their sources"
    },
    {
      "id": "about",
      "label": "About",
      "section": "Advanced",
      "icon": "help-about",
      "description": "Version, build and links"
    }
  ]

  // NPanelWindow's IPC target and Popups.openTab both forward here.
  function openTab(tab) {
    activeTab = tab;
    visible = true;
  }

  Item {
    id: card
    anchors.centerIn: parent
    width: 1040
    height: 800

    Chamfer {
      anchors.fill: parent
      chamferSize: Tokens.chamferPanel
      cutTopRight: true
      cutBottomLeft: true
      fillColor: Colors.alpha(Colors.surface, Tokens.panelOpacity)
      strokeColor: Colors.outline
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

      // ---------------- Sidebar ----------------
      // Pinned with min and max (docs/qml-gotchas.md).
      SettingsSidebar {
        id: sidebar
        Layout.preferredWidth: 200
        Layout.minimumWidth: 200
        Layout.maximumWidth: 200
        Layout.fillHeight: true

        tabs: root.tabs
        searchResults: root.searchResults
        searchQuery: root.searchQuery
        activeTab: root.activeTab
        onSearchQueryEdited: text => root.searchQuery = text
        onTabSelected: id => {
          root.jumpSubTab = "";
          root.activeTab = id;
        }
        onJumpToSearchHit: entry => root.jumpToSearchHit(entry)
      }

      // ---------------- Content ----------------
      SettingsContent {
        Layout.fillWidth: true
        Layout.fillHeight: true

        tabs: root.tabs
        activeTab: root.activeTab
        jumpSubTab: root.jumpSubTab
        onNavigate: (tab, subTab) => root.jumpToSearchHit({
                                                         "tab": tab,
                                                         "subTab": subTab
                                                       })
        onCloseRequested: root.visible = false
        targetScreen: root.targetScreen
        screenName: root.screenName
      }
    }
  }
}
